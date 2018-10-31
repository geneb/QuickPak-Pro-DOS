'**** AMENU.BAS - demonstrates AMenu                        (4/1/1989)

'Copyright (c) 1989 Chris May

DEFINT A-Z

DECLARE SUB AMenu (BYVAL Address, Start, Count, ScanCode, FileColr, HiLiteColr, Rows, Columns, Spacing, Row, Column)
       
N = 450                     'number of elements in array
Start = 31                  'element at which to start

REDIM A$(N)

CLS

FOR I = 1 TO N
   A$(I) = "Element" + STR$(I)
   A$(I) = A$(I) + SPACE$(13 - LEN(A$(I)))
  NEXT I

PRINT "You are welcome to scan all 450 elements ....."
Count = N
AMenu VARPTR(A$(1)), Start, Count, ScanCode, 112, 23, 20, 5, 2, 5, 5
'                                             ^    ^   ^  ^  ^  ^  ^
'                                             ³    ³   ³  ³  ³  ³  ³
'  File Color ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ    ³   ³  ³  ³  ³  ³
'  HiLite Color ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ   ³  ³  ³  ³  ³
'  Number of Rows in table ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ  ³  ³  ³  ³
'  Number of Columns in table ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ  ³  ³  ³
'  Number of spaces between columns ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ  ³  ³
'  Upper left row of display        ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ  ³
'  Upper left column of display     ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ


LOCATE 1, 1
IF ScanCode > 0 THEN PRINT "Control Key #"; ScanCode; "was pressed";
IF ScanCode < 0 THEN PRINT "Keyboard Scan Code #"; -ScanCode; "was pressed";
PRINT SPACE$(50)
PRINT "This demonstrates re-entry into the program    "
PRINT "We will change  "; A$(Count); " to  ";
A$(Count) = "Done" + STR$(Count)
A$(Count) = A$(Count) + SPACE$(13 - LEN(A$(Count)))
PRINT A$(Count)
LOCATE 25, 1: PRINT "Press any key to continue";
WHILE INKEY$ = "": WEND
ScanCode = 3
Count = N
AMenu VARPTR(A$(1)), Start, Count, ScanCode, 112, 23, 20, 5, 2, 5, 5

CLS
PRINT "Now we will demonstrate starting from any point within the array"
PRINT "Lets say   Element 345"
LOCATE 25, 1: PRINT "Press any key to continue";
WHILE INKEY$ = "": WEND
Start = 345
Count = N
AMenu VARPTR(A$(1)), Start, Count, ScanCode, 112, 23, 20, 5, 2, 5, 5

