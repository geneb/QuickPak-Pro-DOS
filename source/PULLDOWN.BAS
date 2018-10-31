'********** PULLDOWN.BAS - Pulldown menu subprogram with mouse support

'Copyright (c) 1988 Don Malin & Crescent Software


DEFINT A-Z

DECLARE SUB BarPrint (Choice$(), BarColor)
DECLARE SUB ButtonPress (Button, Status, Count, X, Y)
DECLARE SUB GetCursor (X, Y, Button)
DECLARE SUB GetVMode (Mode, Page, PageSize, Rows, Columns)
DECLARE SUB HideCursor ()
DECLARE SUB Mouse (A, B, C, D)
DECLARE SUB MouseTrap (ULRow, ULCol, LRRow, LRCol)
DECLARE SUB MQPrint (X$, Colr)
DECLARE SUB MPaintBox (ULRow, ULCol, LRRow, LRCol, Colr)
DECLARE SUB MScrnSave (ULRow, ULCol, LRRow, LRCol, SEG Address)
DECLARE SUB MScrnRest (ULRow, ULCol, LRRow, LRCol, SEG Address)
DECLARE SUB QPrintAny (X$, Clr, MonCode, Row, Col)
DECLARE SUB ShowCursor ()

DECLARE FUNCTION ASCII% (Text$)
DECLARE FUNCTION AltKey% ()
DECLARE FUNCTION DOSVer% ()
DECLARE FUNCTION QPLen% (Text$)

'$INCLUDE: 'DefCnf.Bi'


CONST BarLine = 1               'Line number for the menu bar

                                'Alt Key translation table
CONST AltChars$ = "1234567890     QWERTYUIOP    ASDFGHJKL     ZXCVBNM"

'******************** Display the Menu Bar *****************************
'Note: This is separate so the Main Program can display the Menu Bar
'      before it makes any calls to the PullMen Sub Program.
'***********************************************************************
SUB BarPrint (Choice$(), BarClr) STATIC

    Row = CSRLIN                        'Save the Current Cursor Position
    Col = POS(0)
    MenuBar$ = SPACE$(80)               'Allocate Menu Bar String
    Length = 2
    FOR C = 0 TO UBOUND(Choice$, 2)     'Compose the Menu Bar
        MID$(MenuBar$, Length) = Choice$(0, C)
        Length = Length + QPLen(Choice$(0, C)) + 2
    NEXT
    LOCATE BarLine, 1
    CALL MQPrint(MenuBar$, BarClr)      'Print Menu Bar
    LOCATE Row, Col                     'Relocate the Cursor

    MenuBar$ = ""
END SUB

'****************************************************************************
'   File Name: PULLDOWN.BAS
' Description: Pull Down Menu Sub Program
'          by: Don Malin,  (C) Crescent Software 1988
'
' Parameters:
'
'   Choice$() -
'     The "Choice$" Array holds the Menu Choices.
'     Choice$(0, Menus) hold the Bar Titles.
'     Choice$(Choices, Menu) hold the Window Choices.
'     A "-" value for a choice indicates a dividing line across the menu.
'
'   Stat() -
'     This is an integer array parallel to the Choice$ array.
'     Any value in an element indicates that the choice is inactive
'     (Non-Selectable).
'
'   Menu -
'     Current Menu Number.  A non-zero value on entry will cause that menu
'     to be displayed.
'
'   Choice -
'     Current Menu Choice.  A non-zero value on entry will cause that
'     choice to be displayed.
'
'   Ky$ -
'     This string will contain the character or key code that was used to
'     exit the routine.
'
'   Action -
'     Action is a flag which can be used to control the routine in a
'     multi tasking (polled) mode.  The Action commands are as follows:
'
'       0 - PullDown will take control until an active choice is selected
'           or the [Esc] key is pressed.  (Single Tasking Mode)
'       1 - Used on initial entry for multi-tasking mode.  Only saves the
'           background screen, displays the Menu bar and the current menu.
'           Sets the Action variable to 3 for successive calls.
'       2 - Redisplay the current menu.  Reset Action to 3
'       3 - On entry means just check the keyboard and handle keys used by
'           the routine and exit back to the caller.  On exit means nothing
'           was selected.
'       4 - User made a selection from an active choice or pressed the
'           Escape key so you should check the Menu and Choice variables.
'       5 - Restore the screen, erase the screen buffer used by the routine.
'
' Note: Requires a structure named - "Cnf" defined as "Config".  The
'       structure definition is in the $INCLUDE file "DEFCNF.BAS".
'
' External Routines: MScrnSave, MScrnRest, BarPrint, MPaintBox, MQPrint,
'                    GetCursor
'
'****************************************************************************
'
SUB PullDown (Choice$(), Stat(), Menu, Choice, Ky$, Action, Cnf AS Config) STATIC

    LOCATE , , 0

    IF Action = 4 THEN Action = 1       'See if they forgot to reinit Action
    IF Action < 3 THEN                  'Redisplaying?
       IF Action < 2 THEN               'Redisplaying whole menu?
          LastMenu = UBOUND(Choice$, 2) 'Find Last Bar Menu Choice
                                        'Find screen rows to save
          BotRow = UBOUND(Choice$, 1) + BarLine + 2
          LastChoice = 0
          Size = 80 * (BotRow - BarLine + 1) 'Find memory to alocate
          REDIM ScrBuf(Size)            'Alocate screen memory
          REDIM BarLin(80)
                                        'Save the Bar Line
          MScrnSave BarLine, 1, BarLine, 80, BarLin(0)
                                        'Display the Menu Bar on top line
          CALL BarPrint(Choice$(), Cnf.PulBar)  'Print the Bar Choices

          GetVMode 0, 0, 0, ScRows, 0
          MouseTrap 1, 1, ScRows, 80
          NPixLines = 8
          IF ScRows > 43 AND DOSVer% = 1000 THEN NPixLines = 7
          Wdth = 0
       END IF

       HiBar = Cnf.PulBar \ 16 + 8 + 16 * Cnf.PulBar MOD 16
       GOSUB PullDisplay                'Display the Menu box
       
       IF Action THEN Action = 3        'Reset the Action flag to idle state

       PrevChoice = Choice
       PrevMenu = Menu
       GOSUB PullHilite
    END IF

    IF Choice <> PrevChoice THEN GOSUB PullHilite
    IF Menu <> PrevMenu THEN GOSUB PullDisplay
                                        'If Action flag=5, Restore the screen
    IF Action = 5 AND UBOUND(ScrBuf) > 1 THEN
       MScrnRest BarLine, 1, BarLine, 80, BarLin(0)
       IF Wdth THEN
          MScrnRest BarLine + 1, StartCol, LastChoice + BarLine + 3, EnBar + 3, ScrBuf(0)
       END IF
       ERASE ScrBuf, BarLin             'Clean up memory
       EXIT SUB                         'Bail out
    END IF

    DO
                                        'If we have a Window, Hilight Choice
       AltDown = AltKey                 'Get typed characters
       IF AltDown THEN WasDown = -1

       Ky$ = INKEY$
       IF AltDown = 0 AND WasDown AND AltPressed THEN
          Ky$ = CHR$(13)
          WasDown = 0
          AltPressed = 0
       END IF

       'MMMMMMMMMMMMMMMM Start of Mouse Handling Code MMMMMMMMMMMMMMMMMMM
       'MM   If you hate rodents, exterminate the code from here to    MM
       'MM   the next set of "MMM" comments.                           MM
       'MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
       IF Cnf.Mouse THEN
          ButtonPress 1, Down, Presses, X, Y
          IF Presses = 0 THEN GetCursor X, Y, Button
          MRow = (Y \ NPixLines) + 1
          MCol = (X \ 8) + 1

          IF (MRow <> LMRow OR MCol <> LMCol OR Presses) AND Down = 1 THEN
             
             IF MRow - BarLine - 1 <= LastChoice AND MRow - BarLine - 1 > 0 AND MCol > StartCol AND MCol < EnBar THEN
                Choice = MRow - BarLine - 1
                IF Choice$(Choice, Menu) = "-" OR Stat(Choice, Menu) <> 0 THEN
                   Choice = PrevChoice
                ELSE
                   WasPressed = -1
                END IF
             ELSEIF MRow = BarLine THEN
                TstCol = 1
                LstMen = UBOUND(Choice$, 2)
                FOR N = 0 TO LstMen
                    IF MCol >= TstCol AND MCol <= TstCol + QPLen(Choice$(0, N)) + 1 THEN EXIT FOR
                    TstCol = TstCol + QPLen(Choice$(0, N)) + 2
                NEXT
                IF N <= LstMen THEN Menu = N
                Choice = 0
                IF Menu <> PrevMenu THEN
                   GOSUB PullDisplay
                   Choice = 0
                   PrevChoice = 0
                END IF
                WasPressed = -1
             ELSE
                Choice = 0
                WasPressed = -1
             END IF
             GOSUB PullHilite
          ELSEIF Button AND 2 THEN
             Ky$ = CHR$(27)
             DO
                GetCursor X, Y, Button
             LOOP WHILE Button AND 2
          END IF

          IF Down = 0 AND WasPressed THEN
             WasPressed = 0
             IF MRow - BarLine - 1 <= LastChoice AND MRow - BarLine - 1 > 0 AND MCol > StartCol AND MCol < EnBar THEN
                IF Choice THEN Ky$ = CHR$(13)
             ELSEIF MRow = BarLine THEN
                IF Wdth = 0 OR Active = 0 THEN
                   Ky$ = CHR$(13)
                ELSE
                   Choice = 1
                   DO WHILE Choice$(Choice, Menu) = "-" OR Stat(Choice, Menu)
                      Choice = Choice + 1
                   LOOP
                   GOSUB PullHilite
                END IF
             ELSE
                Ky$ = CHR$(27)
             END IF
          END IF
          
          LMRow = MRow
          LMCol = MCol
       END IF
       'MMMMMMMMMMMMMMMMMMM End of mouse handling code MMMMMMMMMMMMMMMMMMMMMM

       IF AltDown AND QPLen(Ky$) = 2 THEN

          Temp = ASCII(RIGHT$(Ky$, 1))
          IF Temp >= 120 THEN Temp = Temp - 119
          Ky$ = MID$(AltChars$, Temp, 1)

       END IF




       IF QPLen(Ky$) = 1 THEN             'Non extended Keys
          
          IF Ky$ = CHR$(13) OR Ky$ = CHR$(27) THEN
             IF Action = 0 THEN
                MScrnRest BarLine, 1, BarLine, 80, BarLin(0)
                IF Wdth THEN
                   MScrnRest BarLine + 1, StartCol, LastChoice + BarLine + 3, EnBar + 3, ScrBuf(0)
                END IF
                ERASE ScrBuf, BarLin    'Clean up memory
             END IF
             IF Action THEN Action = 4
             EXIT SUB

          ELSEIF Wdth AND Active AND Ky$ <> "-" THEN
             Ky$ = UCASE$(Ky$)          'Make Key Uppercase
             Pass = 0                   'See if User pressed a Choice Letter
             OldChoice = Choice         'Save Current Choice setting
             
             DO                         'Check remaining choices
                IF Choice < LastChoice THEN
                   Choice = Choice + 1
                ELSE
                   Choice = 1
                END IF
               
                WHILE (Stat(Choice, Menu) OR Ky$ <> LEFT$(Choice$(Choice, Menu), 1)) AND Choice < LastChoice
                    Choice = Choice + 1
                WEND
                                        'If we reached the end without finding
                IF Choice >= LastChoice AND (Ky$ <> LEFT$(Choice$(Choice, Menu), 1) OR Stat(Choice, Menu)) THEN
                   IF Pass = 0 THEN
                      Pass = 1
                   ELSE
                      Choice = OldChoice
                      EXIT DO
                   END IF
                ELSE
                   IF AltDown THEN AltPressed = -1
                   EXIT DO
                END IF
             LOOP
             GOSUB PullHilite
          END IF

       ELSEIF QPLen(Ky$) THEN           'Handle Extended Key Codes
                                        
          SELECT CASE ASCII(RIGHT$(Ky$, 1))
             CASE 72                    'Check for Up Arrow Key
                IF Wdth AND Active THEN
                   DO
                      Choice = Choice - 1
                      IF Choice < 1 THEN Choice = LastChoice
                   LOOP WHILE Choice$(Choice, Menu) = "-" OR Stat(Choice, Menu)
                END IF

             CASE 80                    'Check for Down Arrow Key
                IF Wdth AND Active THEN
                   DO
                      Choice = Choice + 1
                      IF Choice > LastChoice THEN Choice = 1
                   LOOP WHILE Choice$(Choice, Menu) = "-" OR Stat(Choice, Menu)
                END IF

             CASE 71                    'Check for Home Key
                IF Wdth AND Active THEN
                   Choice = 1
                   DO WHILE Choice$(Choice, Menu) = "-" OR Stat(Choice, Menu)
                      Choice = Choice + 1
                   LOOP
                END IF

             CASE 79                    'Check for End Key
                IF Wdth AND Active THEN
                   Choice = LastChoice
                   DO WHILE Choice$(Choice, Menu) = "-" OR Stat(Choice, Menu)
                      Choice = Choice - 1
                   LOOP
                END IF

             CASE 75                    'Check for Left Arrow Key
                IF Menu = 0 THEN        'If on Far Left Bar Choice, go to
                   Menu = LastMenu      '  Far Right Choice
                ELSE
                   Menu = Menu - 1      'Otherwise Decrement Bar Choice
                END IF
                Choice = 0
                PrevChoice = 0
                GOSUB PullDisplay       'Display the New Choice Window

             CASE 77                    'Check for Right Arrow Key
                IF Menu = LastMenu THEN 'If on Far Right Bar Choice, go to
                   Menu = 0             '  Far Left Choice
                ELSE
                   Menu = Menu + 1    'Otherwise Increment Bar Choice
                END IF
                Choice = 0
                PrevChoice = 0
                GOSUB PullDisplay       'Display the New Choice Window

             CASE ELSE
          END SELECT

          GOSUB PullHilite
       END IF

       PrevChoice = Choice
       PrevMenu = Menu
    LOOP WHILE Action = 0

    
    EXIT SUB

PullHilite:
    IF Wdth AND Active THEN

       IF PrevChoice > 0 THEN CALL MPaintBox(PrevChoice + BarLine + 1, StartCol + 1, PrevChoice + BarLine + 1, EnBar, Cnf.ActivCh)

       IF Choice > 0 THEN CALL MPaintBox(Choice + BarLine + 1, StartCol + 1, Choice + BarLine + 1, EnBar, Cnf.HiLite)
    END IF
    LOCATE Choice + BarLine + 1, StartCol + 1
RETURN


PullDisplay:
                                        'Restore the screen
    IF Menu <> PrevMenu OR Action < 2 THEN

       IF Wdth THEN
          MScrnRest BarLine + 1, StartCol, LastChoice + BarLine + 3, EnBar + 3, ScrBuf(0)
       END IF
                                        'Re-paint the Menu bar
       IF StartCol THEN CALL MPaintBox(BarLine, StartCol, BarLine, EnCol, Cnf.PulBar)
    END IF
    PrevMenu = Menu                     'Save the menu nunber
  
    StartCol = 1                        'Find the column positions to start
    FOR C = 0 TO Menu - 1               '  and end the hilight on Bar Menu
        StartCol = StartCol + QPLen(Choice$(0, C)) + 2
    NEXT
    EnCol = StartCol + QPLen(Choice$(0, Menu)) + 1
                                        'Hilight the Bar Menu Choice
    CALL MPaintBox(BarLine, StartCol, BarLine, EnCol, HiBar)

    Wdth = 0                            'Find the Width and # of Choices of
    ArrayEnd = UBOUND(Choice$, 1)       '  the new menu
    Active = 0

    IF Choice AND (Stat(Choice, Menu) OR Choice$(Choice, Menu) = "-") THEN Choice = 0
    FOR C = 1 TO ArrayEnd
       ChLen = QPLen(Choice$(C, Menu))
       IF ChLen = 0 THEN EXIT FOR
       IF ChLen > Wdth THEN Wdth = ChLen
       IF Stat(C, Menu) = 0 AND Choice$(C, Menu) <> "-" THEN
          Active = -1
          IF Choice = 0 THEN
             Choice = C
             PrevChoice = C
          END IF
       END IF
    NEXT
    LastChoice = C - 1

    IF StartCol + Wdth + 3 >= 80 THEN   'If the Right Side of the window is
       StartCol = 80 - Wdth - 3         '  off the screen, adjust the Left
    END IF                              '  Side of the window

    EnBar = StartCol + Wdth + 2         'Set the Right Side of the Window

    IF Wdth THEN                        'If there are window choices, print
                                        '  them
       IF Action <> 2 THEN
          MScrnSave BarLine + 1, StartCol, LastChoice + BarLine + 3, EnBar + 3, ScrBuf(0)
       END IF
       HideCursor

       QPrintAny "Õ" + STRING$(Wdth + 2, "Í") + "¸", Cnf.MenBox, -Cnf.MonTyp, BarLine + 1, StartCol

       Temp$ = SPACE$(Wdth)
       FOR C = 1 TO LastChoice
           IF Choice$(C, Menu) = "-" THEN
              QPrintAny "Ã" + STRING$(Wdth + 2, "Ä") + "´", Cnf.MenBox, -Cnf.MonTyp, C + BarLine + 1, StartCol
           ELSE
              QPrintAny "³ ", Cnf.MenBox, -Cnf.MonTyp, C + BarLine + 1, StartCol
              QPrintAny " ³", Cnf.MenBox, -Cnf.MonTyp, C + BarLine + 1, StartCol + Wdth + 2
              LSET Temp$ = Choice$(C, Menu)
              IF Stat(C, Menu) THEN
                 Temp = Cnf.InActCh
              ELSE
                 Temp = Cnf.ActivCh
              END IF
              QPrintAny Temp$, Temp, -Cnf.MonTyp, C + BarLine + 1, StartCol + 2
           END IF
       NEXT

       QPrintAny "À" + STRING$(Wdth + 2, "Ä") + "Ù", Cnf.MenBox, -Cnf.MonTyp, C + BarLine + 1, StartCol
       ShowCursor

       IF EnBar + 2 < 80 THEN
          CALL MPaintBox(BarLine + 2, EnBar + 2, C + BarLine + 2, EnBar + 3, 8)
       END IF

       CALL MPaintBox(C + BarLine + 2, StartCol + 2, C + BarLine + 2, EnBar + 1, 8)
    END IF
RETURN

END SUB

SUB PullMenKey (Ky$, Choice$(), Menu, Init) STATIC

    IF Init THEN
       LstMen = UBOUND(Choice$, 2)
       HotKeys$ = STRING$(LstMen + 1, 0)
       FOR N = 0 TO LstMen
           FstChr$ = UCASE$(LEFT$(LTRIM$(Choice$(0, N)), 1))
           IF QPLen(FstChr$) THEN
              HotKey = INSTR(AltChars$, FstChr$)
              IF HotKey <= 15 THEN
                 HotKey = 119 + HotKey
                 IF HotKey = 119 THEN HotKey = 0
              END IF
              MID$(HotKeys$, N + 1) = CHR$(HotKey)
           END IF
       NEXT
       Init = 0
    END IF

    IF QPLen(Ky$) = 2 THEN
       Menu = INSTR(HotKeys$, RIGHT$(Ky$, 1)) - 1
    ELSE
       Menu = -1
    END IF

    GetCursor X, Y, Button
    IF Button THEN
       MRow = (Y \ 8) + 1
       IF MRow = BarLine THEN
          MCol = (X \ 8) + 1
          LCol = 1
          FOR N = 0 TO LstMen
              IF MCol >= LCol AND MCol <= LCol + QPLen(Choice$(0, N)) + 1 THEN EXIT FOR
              LCol = LCol + QPLen(Choice$(0, N)) + 2
          NEXT
          IF N <= LstMen THEN Menu = N
       END IF
    END IF

END SUB

