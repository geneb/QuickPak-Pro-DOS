'****************************************************************************
' DemoSS.Bas - QuickPak Professional Spreadsheet demonstration program      *
' Copyright (c) 1988 Don Malin, Crescent Software                           *
'****************************************************************************

DEFINT A-Z

'----- Define external routines used by demo
DECLARE SUB Spread (Wks$(), Frmt$(), ColWdths(), Wdth, Rows, Action)
DECLARE FUNCTION Monitor% ()
DECLARE FUNCTION Peek1% (Segment, Address)


COLOR 2, 0                              'use green on black for screen color
CLS                                     'clear the screen

'----- Set up window display parameters
M = Monitor%                            'see what type of monitor is present
EGAByte = Peek1%(0, &H487)              'save the EGA "miscellaneous" byte

SELECT CASE M

   CASE 5                               'EGA monitor
      WIDTH , 43                        'use 43 line mode

      'In 43 line mode, cursor emulation must be disabled for the cursor
      'NOT to be remapped from 6,7 to 11,12.  If this is not done, the
      'cursor will not be visible when editing a cell with F2.
      CALL Poke1(0, &H487, EGAByte OR 1)

      WindRows = 34                     'make display window include 34 lines
      PRINT STRING$(3360, 254);         'fill the screen with dots
      BotLin = 43                       'set the bottom line number for later
      WindRow = 4                       'display window on line 4
  
   CASE 7, 12                           'VGA monitor
      WIDTH , 50                        'use 50 line mode
      CALL Poke1(0, &H487, EGAByte OR 1)'see the comment above
      WindRows = 41                     'make display window include 41 lines
      PRINT STRING$(3920, 254);         'fill the screen with dots
      BotLin = 50                       'set the bottom line number for later
      WindRow = 4                       'display window on line 4
  
   CASE ELSE                            'all other monitor types
      WindRows = 20                     'make display window include 20 lines
      PRINT STRING$(2000, 254);         'fill the screen with dots
      BotLin = 25                       'set the bottom line number for later
      WindRow = 2                       'display window on line 2
END SELECT

'----- Set up for spreadsheet data
Rows = 150                              'maximum number of spread sheet rows
Cols = 28                               'ditto for columns

REDIM Wks$(Rows, Cols)                  'init worksheet data array
REDIM Frmt$(Rows, Cols)                 'init array of formatting strings
REDIM ColWdths(Cols)                    'init table of column widths

'----- Read Worksheet cell data (see DATA statements below)
READ Wks$(1, 1)                         'read the title cell
READ Wks$(2, 1)                         'read the underline for above
FOR R = 4 TO 32                         'read each row of data
    FOR C = 1 TO 5                      'read each column of data
        READ Wks$(R, C)
    NEXT
NEXT

'----- Set formatting info. for cells
FOR R = 6 TO 30
    Frmt$(R, 4) = "$$#####,.##"         'unit price cells
    Frmt$(R, 5) = "$$######,.##"        'total value cells
NEXT
Frmt$(32, 5) = "$$########,.##"         'grand total cell

'----- Set column widths
ColWdths(1) = 26                        'A column
ColWdths(2) = 9                         'B   "
ColWdths(3) = 8                         'C   "
ColWdths(4) = 11                        'D   "
ColWdths(5) = 14                        'E   "
FOR N = 6 TO Cols                       'rest
    ColWdths(N) = 8
NEXT

COLOR 15, 0                             'bright white on black for messages
Action = 0                              'init action flag
WindWdth = 72                           'make the window 72 characters wide

DO
    LOCATE BotLin, 1                    'print instructions on bottom line
    PRINT "Press the slash key (/) to quit the demo";

    '************************************************************************
    'You could also put code here to perform menuing tasks and then return  *
    'to the spreadsheet sub-program.                                        *
    '************************************************************************
  

    '----- Display the Spreadsheet and allow the User to edit it.
    '----- Note: Sub will return when the user presses the "/" key
    LOCATE WindRow, 4
    CALL Spread(Wks$(), Frmt$(), ColWdths(), WindWdth, WindRows, Action)

    LOCATE BotLin, 1
    PRINT "Do again? (Y/N)"; TAB(41);
    LOCATE , 16
    Ky$ = INPUT$(1)

LOOP UNTIL UCASE$(Ky$) = "N"

'----- Clear the window
Action = 5                              'clear window flag
CALL Spread(Wks$(), Frmt$(), ColWdths(), WindWdth, WindRows, Action)
CALL Poke1(0, &H487, EGAByte)           'restore the EGA cursor byte if needed

END



'****************************************************************************
' Spreadsheet DATA statements                                               *
' Notes:                                                                    *
'        String cells must be preceeded with ' or ^ or ` characters         *
'        Numeric cells must begin with a space as is BASIC's default        *
'****************************************************************************

DATA "'          This is the title line of a sample spreadsheet"
DATA "'          =============================================="

DATA "'Part Description",          "`Quantity", "'Units ",  "`Unit Price", "`Total Value"
DATA "'-------------------------", "'--------", "'-------", "'----------", "'-------------"
DATA "'Deck Fill Asy.",            " 26",       "'Pcs.",    " 12.34",      ""
DATA "'Exhaust Hose 3 in.",        " 25",       "'Feet",    " 2.51",       ""
DATA "'Babbit Disk 8 in.",         " 5",        "'Pcs.",    " 85",         ""
DATA "'Shaft Coupler 1.25 in.",    " 5",        "'Pcs.",    " 54.23",      ""
DATA "'Prop. Shaft 1.25 in.",      " 3",        "'Pcs.",    " 250",        ""
DATA "'Stuffing Box 1.25 in.",     " 20",       "'Pcs.",    " 56.23",      ""
DATA "'Cutlass Bearing 1.25 in.",  " 12",       "'Pcs.",    " 23.76",      ""
DATA "'Shaft Zincs 1.25 in.",      " 32",       "'Pcs.",    " 13.42",      ""
DATA "'Beckson Deck Plates",       " 5",        "'Pcs.",    " 29.89",      ""
DATA "'Par Elec. Bilge Pump",      " 2",        "'Pcs.",    " 165.99",     ""
DATA "'Seacocks",                  " 4",        "'Pcs.",    " 231",        ""
DATA "'Heat Exchanger",            " 1",        "'Pcs.",    " 287.23",     ""
DATA "'Beckson Air Ports",         " 8",        "'Pcs.",    " 76.34",      ""
DATA "'Mariman Snatch Blocks",     " 7",        "'Pcs.",    " 165.23",     ""
DATA "'Barient Winches #7890B",    " 2",        "'Pcs.",    " 803.23",     ""
DATA "'Barient Winches #7120A",    " 2",        "'Pcs.",    " 756.89",     ""
DATA "'Barient Winches #5645B",    " 2",        "'Pcs.",    " 506.00",     ""
DATA "'1/4 in. Alum. Plate",       " 100",      "'SqFt.",   " 2.10",       ""
DATA "'3/8 in. Alum. Plate",       " 50",       "'SqFt.",   " 3.23",       ""
DATA "'1/2 in. Alum. Plate",       " 20",       "'SqFt.",   " 4.63",       ""
DATA "'1/4 X 1 in. Flat Stock",    " 106",      "'Feet",    " .82",        ""
DATA "'Silver Label Resin",        " 55",       "'Gallons", " 25.16",      ""
DATA "'Blue Label Resin",          " 55",       "'Gallons", " 15.24",      ""
DATA "'3 oz Glass Cloth",          " 250",      "'SqFt.",   " .46",        ""
DATA "'8 oz Glass Cloth",          " 120",      "'SqFt.",   " .87",        ""
DATA "'-------------------------", "'--------", "'-------", "'----------", "'============="
DATA "",                           "",          "'     Grand Total =", "",   ""

