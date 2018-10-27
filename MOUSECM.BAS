'**** MouseCM.Bas - demonstrates Chris May's mouse routines      (8/1/1989)

'Copyright (c) 1989 Chris May
'QuickBasic must be started with the /ah option for this demo

DEFINT A-Z

TYPE FLen
   S AS STRING * 13
END TYPE

DECLARE SUB MAMenuT (SEG ArrayElement AS FLen, Selection, Start, ElSize, Count, ScanCode, FileColr, HiLiteColr, Rows, Columns, Spacing, Row, Column)
DECLARE SUB MAmenu (BYVAL Address, Selection, Start, Count, ExitCode, FileColr, HiLiteColr, Rows, Columns, Spacing, Row, Column)
DECLARE SUB MEditor (Edit$, Length, ScanCode, NumOnly, CapsOn, NormColor, EditColor, Row, Column, CurCol)
DECLARE SUB MMenuVert (BYVAL Address, Selection, Start, ScanCode, ElemClr, HiLite, NumRow, Row, Column)
DECLARE FUNCTION MGetKey% (Row, Col)
DECLARE FUNCTION WaitKey% ()

CALL InitMouse(There)
CLS
IF NOT There THEN PRINT "Mouse not present but will continue anyway"

'--------------------------------------- MEDITOR
PRINT "MEDITOR DEMO"
Edit$ = "Try editing this string         "
Num.Only = 0
Caps.On = 0
NormColor = 7
EditColor = 23
Row = 10
Col = 15
CurCol = 10
CALL ShowCursor
MEditor Edit$, ALen, ScanCode, Num.Only, Caps.On, NormColor, EditColor, Row, Col, CurCol
CALL HideCursor
LOCATE 1, 1
PRINT "ScanCode = "; ScanCode, "Edit$ = "; Edit$
PRINT "Row = "; Row, , "Col = "; Col
PRINT "Cursor column = "; CurCol, "String length = "; ALen
LOCATE 25, 1: PRINT "Press any key to continue";
CALL ShowCursor
Press = MGetKey(R, C)
CALL HideCursor


'--------------------------------------- MGETKEY
CLS
PRINT "This is a demo of MGETKEY - Press any mouse button or keyboard key"
CALL ShowCursor
ScanCode = MGetKey(Row, Col)
CALL HideCursor
IF ScanCode = 1000 THEN PRINT "Left mouse button was pressed"
IF ScanCode = 1001 THEN PRINT "Right mouse button was pressed"
IF ScanCode = 1002 THEN PRINT "Middle mouse button was pressed"
PRINT "ScanCode = "; ScanCode
PRINT "Row = "; Row, "Col = "; Col
LOCATE 25, 1: PRINT "Press any key to continue";
CALL ShowCursor
Press = MGetKey(R, C)
CALL HideCursor
    

'--------------------------------------- MAMENU
CLS
N = 450                      'number of elements in array
Start = 1                    'element at which to start

REDIM A$(N)

FOR I = 1 TO N
   A$(I) = "Element" + STR$(I)
   A$(I) = A$(I) + SPACE$(13 - LEN(A$(I)))
  NEXT I

Length = LEN(A$(1))

PRINT "MAMENU DEMO :-  Select a file using the mouse ....."

Row = 5                      'Upper left row of display
Col = 5                      'Upper left column of display
Selection = 146
Start = 125

CALL ShowCursor
MAmenu VARPTR(A$(1)), Selection, Start, N, ScanCode, 112, 23, 20, 5, 2, Row, Col
CALL HideCursor
'                                                     ^    ^   ^  ^  ^
'                                                     ³    ³   ³  ³  ³
'                     File Color ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ    ³   ³  ³  ³
'                     HiLite Color ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ   ³  ³  ³
'                     Number of Rows in table ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ  ³  ³
'                     Number of Columns in table ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ  ³
'                     Number of spaces between columns ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

PRINT "Selection = "; Selection, "ScanCode = "; ScanCode
PRINT "Row = "; Row, , "Col = "; Col
LOCATE 25, 1: PRINT "Press any key to continue";
CALL ShowCursor
Press = MGetKey(R, C)
CALL HideCursor
    

'--------------------------------------- MAMENUT
CLS
N = 6666                    'number of elements in array
Start = 1                   'first element in table
Selection = 1               'element on which to put cursor

REDIM B(N) AS FLen

PRINT "Assembling a fixed length string array with 6,666 elements, each of"
PRINT "which is 13 bytes long. That's a total of 86,658 bytes!  Please wait..."

FOR I = 1 TO N
   B(I).S = "Element" + STR$(I)
  NEXT I

CLS
Row = 5
Col = 5
PRINT "MAMENUT DEMO :-  Select a file using the mouse ....."
WHILE INKEY$ <> "": WEND
CALL ShowCursor
MAMenuT B(1), Selection, Start, 13, N, ScanCode, 112, 23, 20, 5, 2, Row, Col
CALL HideCursor
'                                                 ^    ^   ^  ^  ^
'                                                 ³    ³   ³  ³  ³
' File Color ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ    ³   ³  ³  ³
' HiLite Color ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ   ³  ³  ³
' Number of Rows in table ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ  ³  ³
' Number of Columns in table ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ  ³
' Number of spaces between columns ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

PRINT "Selection = "; Selection, "ScanCode = "; ScanCode
PRINT "Row = "; Row, , "Col = "; Col

LOCATE 25, 1: PRINT "Press any key to continue";
Press = WaitKey


'--------------------------------------- MMENUV
CLS
PRINT "This demonstrates a vertical menuing program"

Row = 7
Col = 13
NumRow = 15
ScanCode = 50
Selection = 1
Start = 1
NormClr = 112
HiLite = 23
CALL ShowCursor
MMenuVert VARPTR(A$(1)), Selection, Start, ScanCode, NormClr, HiLite, NumRow, Row, Col
CALL HideCursor
LOCATE 2, 1
PRINT "ScanCode = "; ScanCode
PRINT "Selection = "; Selection, "Start = "; Start
PRINT "Row = "; Row, , "Col = "; Col

