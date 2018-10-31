'********* VERTMENU.BAS

'by Don Malin
'Copyright (c) 1989-1990 Crescent Software

DEFINT A-Z

DECLARE SUB GetCursor (X, Y, Button)
DECLARE SUB APrint (BYVAL Address, NumEls, MidFirst, NumChars, Colr, Page)
DECLARE SUB ButtonPress (Button, Status, Count, X, Y)
DECLARE SUB HideCursor ()
DECLARE SUB MQPrint (X$, Colr)
DECLARE SUB MPaintBox (ULRow, ULCol, LRRow, LRCol, Colr)
DECLARE SUB MScrnSave (ULRow, ULCol, LRRow, LRCol, SEG Address)
DECLARE SUB MScrnRest (ULRow, ULCol, LRRow, LRCol, SEG Address)
DECLARE SUB MGetState (MouseStor$)
DECLARE SUB MSetState (MouseStor$)
DECLARE SUB MouseTrap (ULRow, ULCol, LRRow, LRCol)
DECLARE SUB GetVMode (Mode, Page, PageSize, Rows, Columns)
DECLARE SUB QPrintRC (X$, Row, Col, Colr)
DECLARE SUB ShowCursor ()
DECLARE FUNCTION DOSVer% ()
DECLARE FUNCTION FindLast% (BYVAL Address, Size)
DECLARE FUNCTION MBuffSize% ()
DECLARE FUNCTION MinInt% (Val1, Val2)
DECLARE FUNCTION PDQTimer& ()

'$INCLUDE: 'DefCnf.BI'

'****************************************************************************
'   File Name: VERTMENU.BAS
' Description: Vertical Menu Sub Program
'          by: Don Malin,  (C) Crescent Software 1988
'
' Parameters:
'
'   Choice$() -
'     The "Choice$" Array holds the menu Choices.
'
'   Choice -
'     Current Menu Choice.  A value on entry will cause that choice to be
'     displayed.
'
'   MaxLen -
'     Length of the incoming Choice strings
'
'   BoxBot -
'     Row number of the bottom of the menu box.
'
'   Ky$ -
'     This string will contain the character or key code that was used to
'     exit the routine.
'
'   Action -
'     Action is a flag which can be used to control the routine in a
'     multi tasking (polled) mode.  The Action commands are as follows:
'       0 - Routine will take control until a choice is selected or the
'           [Esc] key is pressed.  (Single Tasking Mode)
'       1 - Used on initial entry for multi-tasking mode.  Saves the
'           background screen, displays the Menu.  Resets itself to
'           Action = 3.
'       2 - Redisplay the menu contents only.  Reset Action to 3
'       3 - On entry means just check the keyboard and handle keys used by
'           the routine and exit back to the caller.  On exit means nothing
'           was selected.
'       4 - User made a selection or pressed Escape.
'           routine.
'       5 - Restore the screen, erase the screen buffer used by the routine.
'
' Note: Requires a structure named - "Cnf" defined as "Config".  This
'       structure is included in "DefCnf.Bi"
'
' External Routines:  MScrnSave, MScrnRest, MPaintBox, MQPrint, Mouse
'************************************************************************
SUB VertMenu (Item$(), Choice, MaxLen, BoxBot, Ky$, Action, Cnf AS Config) STATIC

                                                'Item$() has one dimension
                                                'Choice is the value returned
    IF Action = 4 THEN Action = 1               'See if they forgot to reset
    IF Action < 2 THEN REDIM ScrBuf(1)          'Temp Dim the Screen buffer
    IF Action = 5 AND UBOUND(ScrBuf) > 1 THEN   'Restore the screen if action=5
       MScrnRest Top - 1, LeftMargin, Bottom + 2, RightMargin + 2, ScrBuf(0)
       ERASE ScrBuf
       EXIT SUB
    END IF

    IF Action < 2 THEN
       GetVMode 0, 0, 0, ScRows, 0
       MouseTrap 1, 1, ScRows, 80
       NPixLines = 8
       IF ScRows > 43 AND DOSVer% >= 1000 THEN NPixLines = 7

       IF BoxBot = 0 THEN BoxBot = ScRows - 1
       BoxBot = MinInt(BoxBot, ScRows - 1)

       'Find the Inverse box color for the Scroll Bar
       Fgr = Cnf.MenBox MOD 16
       ScrlClr = (Cnf.MenBox \ 16) + 16 * (Fgr - ((Fgr \ 8) * 8))

       Fill$ = SPACE$(MaxLen + 1)               'used in Dsply to pad spaces

       '---- determine how many choices to display, and where to put the menu
       MaxNum = UBOUND(Item$)                   'find number of active items
       MaxNum = FindLast%(VARPTR(Item$(MaxNum)), MaxNum)

       Top = CSRLIN + 1                         'put the menu at the current
       LeftMargin = POS(0)                      '  cursor location
       Bottom = Top + MaxNum - 1
       More = 0
       LastRow = 0

       IF Bottom >= BoxBot THEN  '<---/-- BoxBot sets lowest row to display
          More = -1              '   /
          Bottom = BoxBot - 1    '<-/
       END IF
       WinSize = Bottom - Top + 1
       RightMargin = LeftMargin + MaxLen + 3

       '----- Save the underlying screen area
       Size = (WinSize + 3) * (RightMargin - LeftMargin + 3)
       REDIM ScrBuf(Size + 1)
       MScrnSave Top - 1, LeftMargin, Bottom + 2, RightMargin + 2, ScrBuf(0)

       '----- Make sure the choice # is in range
       Offset = 0
       IF Choice = 0 OR Choice > MaxNum THEN
          Choice = 1
       END IF

       IF Choice > Offset + WinSize THEN
          Offset = Choice - WinSize
       END IF

       '----- draw border and display items on the screen
       HideCursor
       QPrintRC "É" + STRING$(MaxLen + 2, "Í") + "»", CSRLIN, LeftMargin, Cnf.MenBox
       FOR X = Top TO Bottom                  'Draw sides, display items
           APos = X - Top + 1

           IF Item$(APos + Offset) = "-" THEN
              Item$(APos + Offset) = STRING$(MaxLen, "Ä")
           END IF
           LSET Fill$ = Item$(APos + Offset)
                                                   'Left box side and choice
           QPrintRC "º ", X, LeftMargin, Cnf.MenBox
           QPrintRC Fill$, X, LeftMargin + 2, Cnf.ActivCh
           IF X = Top AND More = -1 THEN           'Draw Up arrow box side
              QPrintRC CHR$(24), X, RightMargin, ScrlClr
           ELSEIF X = Bottom AND More = -1 THEN    'Draw Down arrow box side
              QPrintRC CHR$(25), X, RightMargin, ScrlClr
           ELSEIF More THEN                        'Draw Scroll bar
              QPrintRC "²", X, RightMargin, ScrlClr
           ELSE                                    'Draw normal box side
              QPrintRC "º", X, RightMargin, Cnf.MenBox
           END IF
       NEXT
                                                   'Draw the bottom of box
       QPrintRC "È" + STRING$(MaxLen + 2, "Í") + "¼", X, LeftMargin, Cnf.MenBox

       CALL MPaintBox(Top, RightMargin + 1, Bottom + 1, RightMargin + 2, 8)
       CALL MPaintBox(Bottom + 2, LeftMargin + 2, Bottom + 2, RightMargin + 2, 8)

       ShowCursor

       Fill$ = ""
       LCol = LeftMargin + 1                  'Set variables for Hilite
       RCol = LCol + MaxLen + 1
       OPtr = 0
       GOSUB VertHiLite
    END IF

    IF Action = 2 THEN                        'Redisplay menu contents
       GOSUB VertDisplay
       GOSUB VertHiLite
    END IF

    IF Action THEN Action = 3                 'Reset Action = 3 (Idle state)


    DO

       DO                                     'Look for keys
           Ky$ = INKEY$

           'MMMMMMMMMMMMMMMM Start of Mouse Handling Code MMMMMMMMMMMMMMMMMMM
           'MM   If you hate rodents, exterminate the code from here to    MM
           'MM   the next set of "MMM" comments.                           MM
           'MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
           '----- Get Mouse Coords. and Botton Info.
           IF LEN(MouseStor$) = 0 THEN
              MouseStor$ = SPACE$(MBuffSize%)
           END IF
           MGetState MouseStor$

           ButtonPress 1, Down, Presses, X, Y
           IF Presses = 0 THEN GetCursor X, Y, Button
           MRow = (Y \ NPixLines) + 1          'Convert X, Y to Row and Column
           MCol = (X \ 8) + 1

           '----- If User pressed a button inside the Box, set flag.
           IF Presses THEN
              Inside = 0
              IF MRow >= Top - 1 AND MRow <= Bottom + 1 THEN
                 IF MCol > LeftMargin AND MCol < RightMargin - More THEN
                    MouseTrap Top - 1, LeftMargin + 1, Bottom + 1, RightMargin - More - 1
                    Inside = -1
                 END IF
              END IF
           END IF

           'IF Down = 0 THEN LetGo2& = PDQTimer&

           IF (Down AND 2) THEN
              Ky$ = CHR$(27)

           '----- Button pressed outside the box
           ELSEIF Presses AND NOT Inside THEN
              IF PutBack THEN
                 PutBack = 0
              ELSEIF Presses AND LEN(MouseStor$) > 0 THEN
                 HideCursor
                 MSetState MouseStor$
                 PutBack = -1
                 Presses = 0
              END IF

           '----- Handle only Mouse actions that were initiated inside the box
           ELSEIF Inside THEN
              IF Presses THEN WasPressed = -1

              '----- See if button pressed on the Scroll bar
              IF Presses AND More THEN
                 IF MCol = RightMargin AND MRow > Top AND MRow < Bottom THEN
                                                'See if button pressed on the
                    IF MRow = BarPtr THEN       '  Scroll Bar Pointer
                       OnPtr = -1
                       MouseTrap Top + 1, MCol, Bottom - 1, MCol
                    END IF
                    ScrlBar = -1                'Set Scroll Bar action flag
                 END IF
              END IF
              
              '----- Handle Scroll Bar Mouse actions
              IF ScrlBar THEN
                 IF Down = 0 THEN               'If button let go
                    IF MRow > BarPtr THEN       'If Below the Scroll Pointer
                       Ky$ = CHR$(0) + CHR$(81)         'Page Down
                    ELSEIF MRow < BarPtr THEN           'Must be above Scroll Pointer
                       Ky$ = CHR$(0) + CHR$(73)         'Page Up
                    END IF
                    ScrlBar = 0                 'Action complete so reset flag
                    OnPtr = 0
                    WasPressed = 0
                    MouseTrap 1, 1, ScRows, 80

                 ELSEIF OnPtr THEN              'Move the Scroll Bar Pointer
                    IF LMRow <> MRow THEN
                       BarRow = MRow
                       IF BarRow >= Bottom THEN BarRow = Bottom - 1
                       IF BarRow <= Top THEN BarRow = Top + 1
                       Choice = (BarRow - Top - 1&) * (MaxNum - 1) \ (WinSize - 3) + 1
                       Offset = Choice - 1
                       IF Offset + WinSize > MaxNum THEN Offset = MaxNum - WinSize
                       GOSUB VertDisplay
                       GOSUB VertHiLite
                    END IF
                 END IF

              '----- See if button pressed on Top or Bottom Arrow icons
              ELSEIF Down AND MCol = RightMargin AND More THEN
                 IF PDQTimer& > LstScrl& + 1 THEN       'Delay between updates
                    IF MRow = Top THEN                  'If on top, do Up
                       IF Choice > Offset + 1 THEN Choice = Offset + 2
                       Ky$ = CHR$(0) + CHR$(72)         '  Arrow proc.
                    ELSEIF MRow = Bottom THEN           'If on Bottom, do
                       IF Choice < Offset + WinSize - 1 THEN Choice = Offset + WinSize - 1
                       Ky$ = CHR$(0) + CHR$(80)         '  Down Arrow Proc.
                    END IF
                    LstScrl& = PDQTimer&                'Update Delay
                    IF Presses THEN LstScrl& = PDQTimer& + 4 'If first press,
                 END IF                                 'leave more time
             
              '----- Button pressed on Box Bottom or Top
              ELSEIF More AND Down = 1 AND (MRow < Top OR MRow > Bottom) THEN
                 IF PDQTimer& > LstScrl& + 1 THEN       'Delay between updates
                    IF MRow < Top THEN                  'If higher than Top,
                       Ky$ = CHR$(0) + CHR$(72)         '  Arrow proc.
                    ELSEIF MRow > Bottom THEN           'If Lower than Bottom,
                       Ky$ = CHR$(0) + CHR$(80)         '  Down Arrow Proc.
                    END IF
                    LstScrl& = PDQTimer&                'Update Delay
                    IF Presses THEN LstScrl& = PDQTimer& + 4 'If first press,
                 END IF                                 'leave more time

              '----- Button Pressed or Down on a Choice
              ELSEIF Down THEN
                 IF MRow <> LMRow OR MCol <> LMCol OR Presses THEN
                    IF MRow <= Bottom AND MRow >= Top THEN
                       TChoice = MRow - Top + 1 + Offset 'Calc. Choice number
                       IF LEFT$(Item$(TChoice), 1) <> "Ä" THEN
                          Choice = TChoice
                          FstPrsChoice = Choice
                          GOSUB VertHiLite              'Hi-Lite new choice
                       END IF
                    END IF
                 END IF
             
              '----- If the button was let go
              ELSEIF WasPressed AND Down = 0 THEN
                 IF MRow >= Top AND MRow <= Bottom THEN
                    IF MCol > LeftMargin AND MCol < RightMargin THEN
                       IF PDQTimer& < LetGo& + 10 THEN 'If half second since the last
                          IF LEFT$(Item$(FstPrsChoice), 1) <> CHR$(196) THEN
                             Ky$ = CHR$(13)        '  press/release, do Enter
                             Choice = FstPrsChoice '  proc.
                          END IF
                       ELSE                        'Start last-press timer
                          LetGo& = PDQTimer&
                          FstPrsChoice = Choice
                       END IF
                    END IF
                 END IF
                 WasPressed = 0
                 MouseTrap 1, 1, ScRows, 80
              END IF
             
              IF Down = 0 THEN
                 LMRow = -1
                 LMCol = -1
              ELSE
                 LMRow = MRow                 'Remember were we were so we
                 LMCol = MCol                 '  can detect movement.
              END IF

           END IF
           'MMMMMMMMMMMMMMMMMMMMMM End of Mouse Code MMMMMMMMMMMMMMMMMMMMMMMM

       LOOP WHILE Ky$ = "" AND Action = 0

       KyLen = LEN(Ky$)
                                              
       IF KyLen = 1 THEN                      'Non-extended keys

          SELECT CASE ASC(Ky$)
             CASE 13, 27                      'Enter or Escape key
                IF Action THEN
                   Action = 4
                ELSE
                   MScrnRest Top - 1, LeftMargin, Bottom + 2, RightMargin + 2, ScrBuf(0)
                   ERASE ScrBuf               'Clean up memory
                END IF
                LOCATE , , 1
                EXIT SUB

             CASE 33 TO 122                   'Letter key pressed
                                              'Reset color
                Ky = ASC(UCASE$(Ky$))         'Upper case version of letter
                K2 = ASC(LCASE$(Ky$))         'ditto for lower case
                Pass = -1                     'First pass through choices
                N = Choice                    'Start at current choice + 1
                DO
                   Pass = Pass + 1
                   IF N < MaxNum THEN
                      N = N + 1
                   ELSE N = 1
                   END IF

                   DO WHILE N <= MaxNum         'was N < MaxNum, EW 4-22-92
                      A = ASC(Item$(N))
                      IF A = 91 THEN A = ASC(MID$(Item$(N), 3, 1))
                      IF Ky = A OR K2 = A THEN EXIT DO
                      N = N + 1
                   LOOP
                   IF Ky = A OR K2 = A THEN
                      Choice = N
                      IF Choice > Offset + (Bottom - Top + 1) THEN
                         Offset = Choice - (Bottom - Top + 1)
                         GOSUB VertDisplay
                      END IF
                      IF Choice <= Offset THEN
                         Offset = Choice - 1
                         GOSUB VertDisplay
                      END IF
                      EXIT DO
                   END IF
                LOOP WHILE Choice > 1 AND Pass = 0
                GOSUB VertHiLite

             CASE ELSE
          END SELECT

       ELSEIF KyLen = 2 THEN                  'Reset color

          SELECT CASE ASC(RIGHT$(Ky$, 1))

             CASE 72
                IF Choice > 1 THEN
                   DO
                      Choice = Choice - 1
                      IF Row - 1 < Top THEN Offset = Offset - 1
                   LOOP WHILE LEFT$(Item$(Choice), 1) = "Ä"
                   GOSUB VertDisplay
                ELSEIF More = 0 THEN
                   Choice = MaxNum
                END IF

             CASE 80
                IF Choice < MaxNum THEN
                   DO
                      Choice = Choice + 1
                      IF Row + 1 > Bottom THEN Offset = Offset + 1
                   LOOP WHILE LEFT$(Item$(Choice), 1) = "Ä"
                   GOSUB VertDisplay
                ELSEIF More = 0 THEN
                   Choice = 1
                END IF

             CASE 73
                IF Offset > 0 THEN
                   IF Offset - WinSize > 0 THEN
                      Offset = Offset - WinSize
                   ELSE Offset = 0
                   END IF
                   Choice = (Row - Top + 1) + Offset
                   GOSUB VertDisplay
                END IF

             CASE 81
                IF Offset + 2 * WinSize < MaxNum THEN
                   Offset = Offset + WinSize
                ELSE Offset = MaxNum - WinSize
                END IF
                Choice = (Row - Top + 1) + Offset
                GOSUB VertDisplay

             CASE 71
                Choice = 1
                Offset = 0
                GOSUB VertDisplay

             CASE 79
                Choice = MaxNum
                Offset = MaxNum - (Bottom - Top + 1)
                GOSUB VertDisplay

             CASE ELSE

          END SELECT
          GOSUB VertHiLite
       END IF

    LOOP WHILE Action = 0                     'get again if not multi-tasking

    MouseStor$ = ""

    EXIT SUB


VertHiLite:
    Row = Top + (Choice - Offset) - 1
    IF LastRow > 0 AND Row <> LastRow THEN CALL MPaintBox(LastRow, LCol, LastRow, RCol, Cnf.ActivCh)
    CALL MPaintBox(Row, LCol, Row, RCol, Cnf.HiLite)   'set inverse color
    LastRow = Row
   
    IF More THEN

       BarPtr = Choice * (WinSize - 3&) \ (MaxNum - 1) + Top + 1

       IF BarPtr <> OPtr THEN
          IF OPtr THEN
             LOCATE OPtr, RightMargin  'Update the Scroll Bar position
             CALL MQPrint("²", ScrlClr)
          END IF
          LOCATE BarPtr, RightMargin
          CALL MQPrint(CHR$(8), Cnf.MenBox)
       END IF
       OPtr = BarPtr
    END IF

    LOCATE Row, LCol + 1

RETURN

'----- Print the choices in the window
VertDisplay:
    IF Choice <= Offset THEN Offset = Choice - 1
    IF Choice > Offset + WinSize THEN
       Offset = Choice - WinSize
    END IF

    LOCATE Top, LeftMargin + 2
    APrint VARPTR(Item$(Offset + 1)), Bottom - Top + 1, 1, MaxLen, -1, -1

RETURN

END SUB

