'$SubTitle:'Pull Down Menu routines'
'***** PullDnMS.Bas - Pull Down menu subprogram with Hot Key support.
'                     Resembles and behaves like MicroSoft's pull downs.

'Copyright (c) 1989-1990 Crescent Software
'by Don Malin


DEFINT A-Z

DECLARE SUB BarPrint (Choice$(), Stat())
DECLARE SUB Box0 (UlRow, UlCol, BrRow, BrCol, BoxType, Clr)
DECLARE SUB ButtonPress (Button, Status, Count, X, Y)
DECLARE SUB GetCursor (X, Y, Button)
DECLARE SUB GetVMode (Mode, Page, PageSize, Rows, Columns)
DECLARE SUB HideCursor ()
DECLARE SUB MouseTrap (UlRow, UlCol, LRRow, LRCol)
DECLARE SUB MQPrint (X$, Colr)
DECLARE SUB MPaintBox (UlRow, UlCol, LRRow, LRCol, Colr)
DECLARE SUB MScrnSave (UlRow, UlCol, LRRow, LRCol, SEG Address)
DECLARE SUB MScrnRest (UlRow, UlCol, LRRow, LRCol, SEG Address)
DECLARE SUB QPrintRC (X$, Row%, Col%, Clr%)
DECLARE SUB ShowCursor ()

DECLARE FUNCTION ASCII% (Text$)
DECLARE FUNCTION AltKey% ()
DECLARE FUNCTION DOSVer% ()
DECLARE FUNCTION InStat% ()
DECLARE FUNCTION PullMenKey% (Ky$, Choice$(), Stat%())

CONST BarLine = 1               'Line number for the menu bar
CONST BarLCol = 1               'Left column where the bar starts
CONST BarRCol = 80              'Right column where the bar ends

CONST MenuClr = 112             'Menu Color
CONST InActClr = 120            'Inactive choice color
CONST HiliteClr = 7             'Highlight bar color

DIM SHARED HotLtrClr            'Menu Hot Key letter color
DIM SHARED HiliteHotClr         'Highlight hot key color

                                'Alt Key translation table
CONST AltChars$ = "1234567890     QWERTYUIOP    ASDFGHJKL     ZXCVBNM"


DIM SHARED Temp, N, LastMenu, MRow, MCol, LCol, RCol, Button, AltUsed

'****************************************************************************
'Displays the menu bar on the line specified by the constant "BarLine".
'Also initializes a "Hot Key" table for use with "PullMenKey"
'
'   Choice$() -
'     The "Choice$" Array holds the Menu Choices.
'     Choice$(0, Menus) hold the Bar Titles.
'
'   Stat() -
'     This is an integer array parallel to the Choice$ array.
'     A value in the low byte of elements (M, 0) indicates the offset + 2
'     from the left menu title to display.  The high byte of the element
'     indicates the offset of the hot key letter.
'
'Note: This is separate so your Program can display the Menu Bar before it
'      makes any calls to the PullMenKey or PullDnMS Sub Programs.
'****************************************************************************
'
SUB BarPrint (Choice$(), Stat()) STATIC

    SHARED HotKeys$                             'Share "Menu" Hot key table

    IF NOT BeenHere THEN
       Cmd$ = UCASE$(COMMAND$)
       BeenHere = -1
    END IF
    IF INSTR(Cmd$, "/NOHI") THEN                'Check for command line color
       IF INSTR(Cmd$, "/B") THEN                '  overrides.
          HotLtrClr = 7                         'Menu Hot Key letter color
          HiliteHotClr = 112                    'Highlight hot key color
       ELSE
          HotLtrClr = 116
          HiliteHotClr = 2
       END IF
    ELSE
       HotLtrClr = 127
       HiliteHotClr = 15
    END IF
   
    LastMenu = UBOUND(Choice$, 2)               'Get the last menu number
    HotKeys$ = STRING$(LastMenu + 1, 0)         'Make string for Hot key table
    Bar$ = SPACE$(BarRCol - BarLCol + 1)        'Make a string for Menu Bar
    Temp = 4                                    'Put first Menu title @ pos. 4

    FOR N = 0 TO LastMenu                       'Examine each Menu title
                                                'Get the Hot key character
                                                '  from the given offset
        HotChr$ = UCASE$(MID$(Choice$(0, N), Stat(0, N) \ 256 + 1, 1))
        HotKey = INSTR(AltChars$, HotChr$)      'Get it's position in table
        IF HotKey <= 15 THEN                    'Is it a number?
           HotKey = 119 + HotKey                'Add 119
           IF HotKey = 119 THEN HotKey = 0      'Special case for "M"
        END IF
        MID$(HotKeys$, N + 1) = CHR$(HotKey)    'Put the character in table

        MID$(Bar$, Temp) = Choice$(0, N)        'Put Menu title in Bar string
        IF N < LastMenu THEN                    'Get position for next title
           Temp = Temp + Stat(0, N + 1) MOD 256 + LEN(Choice$(0, N)) + 2
        END IF
    NEXT

    HideCursor
    QPrintRC Bar$, BarLine, BarLCol, MenuClr    'Print the Menu title line
    ShowCursor

END SUB

'****************************************************************************
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
'     Any value in the low byte of an element indicates that the choice is
'     inactive (Non Selectable).  The high byte of the element indicates
'     the offset (0 based) of the hot key letter.
'
'   Menu -
'     Current Menu Number.  A nonzero value on entry will cause that menu
'     to be displayed.
'
'   Choice -
'     Current Menu Choice.  A nonzero value on entry will cause that
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
'       0 - PullDnMS will take control until an active choice is selected
'           or the [Esc] key is pressed.  (Single Tasking Mode)
'       1 - Used on initial entry for multitasking mode.  Only saves the
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
'****************************************************************************
'
SUB PullDnMs (Choice$(), Stat(), Menu, Choice, Ky$, Action) STATIC

    LOCATE , , 0

    IF Action = 4 THEN Action = 1       'See if they forgot to reinit. Action
    IF Action < 3 THEN                  'Redisplaying?
       IF Action < 2 THEN               'Redisplaying whole menu?
          LastMenu = UBOUND(Choice$, 2) 'Find Last Bar Menu Choice
          LastChoice = 0
          Wdth = 0
                                        'Find screen rows to save
          Temp = 80 * (UBOUND(Choice$, 1) + BarLine + 3)
          REDIM ScrBuf(Temp)            'Allocate screen memory
          REDIM BarLin(80)              'Save the Bar Line
          MScrnSave BarLine, 1, BarLine, 80, BarLin(0)
                                        
          BarPrint Choice$(), Stat()    'Display the Menu Bar
          
          GetVMode 0, 0, 0, Temp, 0     'Setup the mouse
          MouseTrap 1, 1, Temp, 80
          NPixLines = 8
          IF Temp > 43 AND DOSVer% >= 1000 THEN NPixLines = 7
          
       END IF

       ArrayEnd = UBOUND(Choice$, 1)

       GOSUB PullDisplay                'Display the Menu box
       
       IF Action THEN Action = 3        'Reset the Action flag to idle state

       PrevChoice = Choice
       PrevMenu = Menu
       ButtonPress 1, Down, Presses, MCol, MRow
       IF Down = 0 THEN GOSUB PullHilite
    END IF

                                        'If Action flag=5, Restore the screen
    IF Action = 5 AND UBOUND(ScrBuf) > 1 THEN
       GOSUB CleanUp
       PrevChoice = Choice
       PrevMenu = Menu
       AltUsed = 0
       EXIT SUB                         'Bail out
    END IF

    IF Choice <> PrevChoice THEN GOSUB PullHilite
    IF Menu <> PrevMenu THEN GOSUB PullDisplay



    DO
                                        'If we have a Window, Highlight Choice
                                        'Get typed characters
       Ky$ = INKEY$

       'MMMMMMMMMMMMMMMM Start of Mouse Handling Code MMMMMMMMMMMMMMMMMMM
       'MM   If you hate rodents, exterminate the code from here to    MM
       'MM   the next set of "MMM" comments.                           MM
       'MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
       ButtonPress 1, Down, Presses, MCol, MRow
       IF Presses = 0 THEN GetCursor MCol, MRow, Button
       MRow = (MRow \ NPixLines) + 1
       MCol = (MCol \ 8) + 1

       IF (MRow <> LMRow OR MCol <> LMCol OR Presses) AND Down = 1 THEN
          WasPressed = -1
          IF MRow - BarLine - 1 <= LastChoice AND MRow - BarLine - 1 > 0 AND MCol >= StartCol AND MCol <= EnBar THEN
             Choice = MRow - BarLine - 1
             IF Choice$(Choice, Menu) = "-" THEN
                Choice = PrevChoice
                WasPressed = 0
             END IF
             GOSUB PullHilite
          ELSEIF MRow = BarLine THEN
             Temp = BarLCol + 2
             FOR N = 0 TO LastMenu
                 IF MCol >= Temp AND MCol <= Temp + LEN(Choice$(0, N)) + 1 THEN EXIT FOR
                 IF N < LastMenu THEN
                    Temp = Temp + Stat(0, N + 1) MOD 256 + LEN(Choice$(0, N)) + 2
                 END IF
             NEXT
             IF N <= LastMenu THEN Menu = N
             IF Menu <> PrevMenu THEN GOSUB PullDisplay
          END IF
          
       ELSEIF Button AND 2 THEN
          Ky$ = CHR$(27)
          DO
             GetCursor MCol, MRow, Button
          LOOP WHILE Button AND 2
       END IF

       IF Down = 0 AND WasPressed THEN
          WasPressed = 0
          IF MRow - BarLine - 1 <= LastChoice AND MRow - BarLine - 1 > 0 AND MCol >= StartCol AND MCol <= EnBar THEN
             Ky$ = CHR$(13)
          ELSEIF MRow = BarLine THEN
             IF Wdth = 0 THEN
                Ky$ = CHR$(13)
             ELSE
                GOSUB PullHilite
             END IF
          ELSE
             Ky$ = CHR$(27)
          END IF
       END IF
          
       IF Down = 0 THEN
          LMRow = -1
          LMCol = -1
       ELSE
          LMRow = MRow
          LMCol = MCol
       END IF
       'MMMMMMMMMMMMMMMMMMM End of mouse handling code MMMMMMMMMMMMMMMMMMMMMM


       IF LEN(Ky$) THEN

          K = ASCII(RIGHT$(Ky$, 1))
          IF LEN(Ky$) = 2 THEN
             IF AltKey THEN
                IF K >= 120 THEN K = K - 119
                K = ASCII(MID$(AltChars$, K, 1))
             ELSE
                K = -K
             END IF
          END IF

          SELECT CASE K
             CASE 13, 27
                IF Stat(Choice, Menu) MOD 256 = 0 OR K = 27 THEN
                   IF Action = 0 THEN
                      GOSUB CleanUp
                      EXIT SUB
                   ELSE
                      Action = 4
                   END IF
                ELSEIF K = 13 THEN
                   Ky$ = ""
                END IF

             CASE 32 TO 254
                IF Wdth AND K <> 45 THEN 'See if User pressed a Choice Letter
                                                'Make Key Uppercase
                   IF K >= 97 AND K <= 122 THEN K = K - 32

                   Temp = 0
             
                   DO
                      Choice = Choice + 1
                      IF Choice > LastChoice THEN
                         IF Temp THEN EXIT DO
                         Choice = 1
                         Temp = Choice
                      END IF
                      Ltr = ASCII(UCASE$(MID$(Choice$(Choice, Menu), Stat(Choice, Menu) \ 256 + 1, 1)))
                   LOOP WHILE K <> Ltr OR Stat(Choice, Menu) MOD 256

                   IF K <> Ltr OR Choice > LastChoice THEN
                      Choice = PrevChoice
                   ELSE
                      Ky$ = CHR$(13)
                      AltUsed = AltKey
                      IF Action = 0 THEN
                         GOSUB CleanUp
                         EXIT SUB
                      ELSE
                         Action = 4
                      END IF
                   END IF
                END IF

             CASE -72                   'Up Arrow Key
                IF Wdth THEN
                   Choice = Choice - 1 + (Choice$(Choice - 1, Menu) = "-")
                   IF Choice < 1 THEN Choice = LastChoice
                END IF

             CASE -80                   'Down Arrow Key
                IF Wdth THEN
                   IF Choice >= LastChoice THEN Choice = 0
                   Choice = Choice + 1 - (Choice$(Choice + 1, Menu) = "-")
                END IF

             CASE -71                   'Home Key
                IF Wdth THEN Choice = 1

             CASE -79                   'End Key
                IF Wdth THEN Choice = LastChoice

             CASE -75                   'Left Arrow Key
                IF Menu = 0 THEN        'If on Far Left Bar Choice, go to
                   Menu = LastMenu      '  Far Right Choice
                ELSE
                   Menu = Menu - 1      'Otherwise Decrement Bar Choice
                END IF
                GOSUB PullDisplay       'Display the New Choice Window

             CASE -77                   'Right Arrow Key
                IF Menu = LastMenu THEN 'If on Far Right Bar Choice, go to
                   Menu = 0             '  Far Left Choice
                ELSE
                   Menu = Menu + 1      'Otherwise Increment Bar Choice
                END IF
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
    IF Wdth THEN
       IF PrevChoice THEN
          IF Stat(PrevChoice, Menu) MOD 256 THEN
             Clr = InActClr
          ELSE
             Clr = MenuClr
          END IF
          Row = PrevChoice + BarLine + 1
          LCol = StartCol
          RCol = EnBar
          GOSUB PaintIt
          IF Clr = MenuClr THEN
             LCol = StartCol + 1 + (Stat(PrevChoice, Menu) \ 256)
             RCol = LCol
             Clr = HotLtrClr
             GOSUB PaintIt
          END IF
       END IF

       IF Choice THEN
          Row = Choice + BarLine + 1
          LCol = StartCol
          RCol = EnBar
          Clr = HiliteClr
          GOSUB PaintIt
          IF Stat(Choice, Menu) MOD 256 = 0 THEN
             LCol = StartCol + 1 + (Stat(Choice, Menu) \ 256)
             RCol = LCol
             Clr = HiliteHotClr
             GOSUB PaintIt
          END IF
       END IF
    END IF
    LOCATE Choice + BarLine + 1, StartCol + 1
RETURN


PullDisplay:
                                        'Restore the screen
    IF Menu <> PrevMenu OR Action < 2 THEN

       IF Wdth THEN
          MScrnRest BarLine + 1, StartCol - 1, LastChoice + BarLine + 3, EnBar + 3, ScrBuf(0)
       END IF
                                        'Repaint the Menu bar
       IF StartCol THEN
          Row = BarLine
          LCol = StartCol
          RCol = EnCol
          Clr = MenuClr
          GOSUB PaintIt
       END IF
       IF Menu <> PrevMenu OR Choice = 0 THEN Choice = 1
       PrevChoice = Choice
    END IF
    PrevMenu = Menu                     'Save the menu number

    StartCol = BarLCol + 2              'Find the column positions to start
    FOR C = 0 TO Menu - 1               '  and end the highlight on Bar Menu
        StartCol = StartCol + LEN(Choice$(0, C)) + 2 + Stat(0, C + 1) MOD 256
    NEXT
    EnCol = StartCol + LEN(Choice$(0, Menu)) + 1
                                        'Highlight the Bar Menu Choice
    Row = BarLine
    LCol = StartCol
    RCol = EnCol
    Clr = HiliteClr
    GOSUB PaintIt
   
    Wdth = 0                            'Find the Width and # of Choices of
                                        '  the new menu
    FOR C = 1 TO ArrayEnd
       ChLen = LEN(Choice$(C, Menu))
       IF ChLen = 0 THEN EXIT FOR
       IF ChLen > Wdth THEN Wdth = ChLen
    NEXT
    LastChoice = C - 1

    IF StartCol + Wdth + 2 > 80 THEN    'If the Right Side of the window is
       StartCol = 80 - Wdth - 2         '  off the screen, adjust the Left
    END IF                              '  Side of the window


    EnBar = StartCol + Wdth + 1         'Set the Right Side of the Window
    

    IF Wdth THEN                        'If there are window choices, print
                                        '  them
       IF Action <> 2 THEN
          MScrnSave BarLine + 1, StartCol - 1, LastChoice + BarLine + 3, EnBar + 3, ScrBuf(0)
       END IF
       HideCursor

       Box0 BarLine + 1, StartCol - 1, LastChoice + BarLine + 2, EnBar + 1, 1, MenuClr
       Buf$ = SPACE$(Wdth + 2)

       FOR C = 1 TO LastChoice
           IF Choice$(C, Menu) = "-" THEN
              QPrintRC "Ã" + STRING$(Wdth + 2, "Ä") + "´", C + BarLine + 1, StartCol - 1, MenuClr
           ELSE

              LSET Buf$ = " " + Choice$(C, Menu)
              IF Stat(C, Menu) MOD 256 THEN
                 Clr = InActClr
              ELSE
                 Clr = MenuClr
              END IF
              QPrintRC Buf$, C + BarLine + 1, StartCol, Clr
           END IF
           IF Stat(C, Menu) MOD 256 = 0 AND Choice$(C, Menu) <> "-" THEN
              Row = C + BarLine + 1
              LCol = StartCol + 1 + (Stat(C, Menu) \ 256)
              RCol = LCol
              Clr = HotLtrClr
              GOSUB PaintIt
           END IF
       NEXT

       ShowCursor

       IF StartCol + Wdth + 4 <= 80 THEN
          MPaintBox BarLine + 2, EnBar + 2, C + BarLine + 2, EnBar + 3, 8
       END IF
       Row = C + BarLine + 2
       LCol = StartCol + 1
       RCol = EnBar + 1
       Clr = 8
       GOSUB PaintIt
    END IF
RETURN


PaintIt:
    MPaintBox Row, LCol, Row, RCol, Clr
RETURN


CleanUp:
    MScrnRest BarLine, 1, BarLine, 80, BarLin(0)
    IF Wdth THEN
       MScrnRest BarLine + 1, StartCol - 1, LastChoice + BarLine + 3, EnBar + 3, ScrBuf(0)
    END IF
    ERASE ScrBuf, BarLin             'Clean up memory
RETURN

END SUB

'****************************************************************************
'Checks for menu bar hot keys (Alt+Menu Letter).  Also checks for mouse
'presses on the menu bar.  Can be polled by your program to see if the User
'has done any thing to invoke the pull down menu.
'
'   Ky$ -
'     Passes the key string to check.
'
'   Choice$() -
'     The "Choice$" Array holds the Menu Choices.
'     Choice$(0, Menus) hold the Bar Titles.
'
'   Stat() -
'     This is an integer array parallel to the Choice$ array.
'     The high byte of the element indicates the offset of the hot key letter.
'
'  The function will return -1 if no menu was selected, otherwise it will
'  return the menu number of the User's choice.
'****************************************************************************
'
FUNCTION PullMenKey% (Ky$, Choice$(), Stat()) STATIC

    SHARED HotKeys$

    IF LEN(Ky$) = 2 THEN
       Menu = INSTR(HotKeys$, RIGHT$(Ky$, 1)) - 1
    ELSE
       Menu = -1
    END IF

    GetCursor MCol, MRow, Button
    IF Button THEN
       LastMenu = UBOUND(Choice$, 2)
       MRow = (MRow \ 8) + 1
       IF MRow = BarLine THEN
          MCol = (MCol \ 8) + 1
          Temp = BarLCol + 2
          FOR N = 0 TO LastMenu
              IF MCol >= Temp AND MCol <= Temp + LEN(Choice$(0, N)) + 1 THEN
                 Menu = N
                 EXIT FOR
              END IF
              IF N < LastMenu THEN
                 Temp = Temp + Stat(0, N + 1) MOD 256 + LEN(Choice$(0, N)) + 2
              END IF
          NEXT
       END IF
    END IF

    IF AltUsed THEN AltUsed = AltKey
   
    IF Menu = -1 AND NOT AltUsed THEN
       IF AltKey THEN
          IF WasDown = 0 THEN
             WasDown = -1
             IF NOT Bar THEN
                LastMenu = UBOUND(Choice$, 2)
                Temp = BarLCol + 2
                Clr = HotLtrClr
                FOR N = 0 TO LastMenu
                    LCol = Temp + (Stat(0, N) \ 256) + 1
                    RCol = LCol
                    GOSUB PaintIt2
                    IF N < LastMenu THEN
                       Temp = Temp + LEN(Choice$(0, N)) + 2 + Stat(0, N + 1) MOD 256
                    END IF
                NEXT
                LOCATE , , 0
             END IF
          ELSEIF LEN(Ky$) THEN
             WasDown = 0
             KeyWasPressed = -1
          END IF

       ELSEIF WasDown THEN
          WasDown = 0
          IF Bar OR InStat OR LEN(Ky$) OR KeyWasPressed THEN
             GOSUB UndoBar
             KeyWasPressed = 0
             IF InStat = 0 AND LEN(Ky$) = 0 THEN Ky$ = CHR$(27)
          ELSE
             Bar = -1
             BarCh = 0
             PrevBarCh = 0
             GOSUB HiLiteBar
          END IF
       END IF

       IF Bar AND Menu = -1 THEN
          IF LEN(Ky$) THEN
             IF LEN(Ky$) = 1 THEN
                Ky$ = UCASE$(Ky$)
                K = ASCII(Ky$)
             ELSE
                K = -ASCII(RIGHT$(Ky$, 1))
             END IF
             SELECT CASE K
                CASE 13, -72, -80
                   Menu = BarCh
                   Ky$ = ""
                CASE 27, -83
                   GOSUB UndoBar
                CASE 32 TO 255
                   FOR N = 0 TO LastMenu
                       IF Ky$ = UCASE$(MID$(Choice$(0, N), Stat(0, N) \ 256 + 1, 1)) THEN
                          Menu = N
                          EXIT FOR
                       END IF
                   NEXT
                   IF N > LastMenu THEN
                      GOSUB UndoBar
                   ELSE
                      Ky$ = ""
                   END IF
                CASE -75
                   BarCh = BarCh - 1
                   IF BarCh < 0 THEN BarCh = LastMenu
                   GOSUB HiLiteBar
                   Ky$ = ""
                CASE -77
                   BarCh = BarCh + 1
                   IF BarCh > LastMenu THEN BarCh = 0
                   GOSUB HiLiteBar
                   Ky$ = ""
                CASE ELSE
                   GOSUB UndoBar
             END SELECT
           
          END IF
       END IF
    END IF

    IF Menu > -1 THEN
       GOSUB UndoBar
       WasDown = 0
       LOCATE , , 1
    END IF

    PullMenKey% = Menu

    EXIT FUNCTION


HiLiteBar:

    IF BarCh <> PrevBarCh THEN
       IF StartCol THEN
          LCol = StartCol
          RCol = EnCol
          Clr = MenuClr
          GOSUB PaintIt2
          
          LCol = StartCol + 1 + (Stat(0, PrevBarCh) \ 256)
          RCol = LCol
          Clr = HotLtrClr
          GOSUB PaintIt2
       END IF
    END IF
    PrevBarCh = BarCh                   'Save the menu number
                                     
    StartCol = BarLCol + 2              'Find the column positions to start
    FOR N = 0 TO BarCh - 1              '  and end the highlight on Bar Menu
        StartCol = StartCol + LEN(Choice$(0, N)) + 2 + Stat(0, N + 1) MOD 256
    NEXT
    EnCol = StartCol + LEN(Choice$(0, N)) + 1
                                        'Highlight the Bar Menu Choice
    LCol = StartCol
    RCol = EnCol
    Clr = HiliteClr
    GOSUB PaintIt2
    
    LCol = StartCol + 1 + (Stat(0, BarCh) \ 256)
    RCol = LCol
    Clr = HiliteHotClr
    GOSUB PaintIt2

RETURN

PaintIt2:
    MPaintBox BarLine, LCol, BarLine, RCol, Clr
RETURN


UndoBar:

    Bar = 0
    BarPrint Choice$(), Stat()

RETURN

END FUNCTION

'****************************************************************************
'Sets the low byte of a word (Stat() element) without affecting the high byte.
'Used to set the Status byte of an element of the "Stat" array without
'disturbing the "Hot key offset" byte.
'
'  Status -
'    Status word to be set.  ie. Stat(Choice, Menu)
'
'  Truth -
'    Value to set.  ie. "Truth = LEN(FileName$) = 0"
'
'Example: CALL SetStatus(Stat(5, 0), LEN(FileName$) = 0)
'****************************************************************************
'
SUB SetStatus (Status, Truth) STATIC

    Status = 256 * (Status \ 256) + ABS(Truth)

END SUB

