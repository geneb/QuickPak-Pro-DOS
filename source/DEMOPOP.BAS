'********** DemoPop.Bas - demo of the QuickPak Professional pop-up subprograms

'Copyright (c) 1988 Crescent Software


DEFINT A-Z
DECLARE SUB ASCIIChart (Row, Column, Lines)
DECLARE SUB Calc (ULRow, ULCol, FG, BG)
DECLARE SUB Calendar (Mnth, Dy, Yr, ULRow, ULCol, Colr1, Colr2, Action)
DECLARE SUB CSMsgBox (Message$, Wdth, Cnf AS ANY)
DECLARE FUNCTION Monitor% ()

'$INCLUDE: 'DefCnf.BI'          'defines the TYPE variable for MsgBox
'$INCLUDE: 'SetCnf.BI'          'queries the system info for MsgBox

'create a background pattern to show how pop-ups save the underlying screen
CLS
LOCATE , , 0
COLOR 2
PRINT STRING$(22 * 80, 254)
COLOR 14



'----- ASCII Chart

Row = 3: Column = 10: Height = 16
LOCATE 23, 1: PRINT "Use:      PgUp  PgDn  Home  End - Esc when finished "
CALL ASCIIChart(Row, Column, Height)
LOCATE 23, 1: PRINT TAB(54);



'----- Calculator

Row = 2: Column = 50
SELECT CASE Monitor%            'see what type of monitor is present
   CASE 3, 5, 7, 9, 10, 12      'CGA, EGA, VGA color
      FG = 11
      BG = 1
   CASE ELSE                    'monochrome
      FG = 15
      BG = 0
END SELECT

CALL NumOn              'turn on the NumLock key
CALL Calc(Row, Column, FG, BG)
CALL NumOff



'----- Calendar

Colr1 = 2: Colr2 = 15   'b/w calendar colors (try 66 and 77 for CGA/EGA)
ULRow = 3: ULCol = 14   'upper left corner of calendar

Mnth = VAL(LEFT$(DATE$, 2))     'take today's date from DOS
Yr = VAL(RIGHT$(DATE$, 4))
Dy = VAL(MID$(DATE$, 4, 2))

Action = 1                      'display the calendar
CALL Calendar(Mnth, Dy, Yr, ULRow, ULCol, Colr1, Colr2, Action)
CALL WaitKey

Action = 0                      'remove the calendar
CALL Calendar(Mnth, Dy, Yr, ULRow, ULCol, Colr1, Colr2, Action)



'----- MsgBox - word wraps a message

FOR X = 1 TO 8          'create a long message to show how MsgBox centers
    READ L$             '  and word-wraps it within the window
    Message$ = Message$ + L$
NEXT
DATA "This subprogram displays a message that is contained in a single long "
DATA "string.  The first time it is called the underlying screen is saved, "
DATA "and then the message is word-wrapped and displayed correctly centered.  "
DATA "To clear the message and restore the underlying screen, simply call it "
DATA "again.  No additional passed parameters are required, because it keeps "
DATA "track of how many times it has been called internally.  MsgBox is "
DATA "ideal for situations where you have a long message to be displayed, "
DATA "but don't want to bother having to deal with how it will be formatted."

Wdth = 54                'a box 54 characters wide will be centered on screen
LOCATE 3                 'the top of the box goes on line 3
CALL CSMsgBox(Message$, Wdth, Cnf)
CALL WaitKey
CALL CSMsgBox("", 0, Cnf) 'the parameters used the second time don't matter
                          ' as long as the message string is null
