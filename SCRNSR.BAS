'********** ScrnSR.Bas - demonstration for saving/restoring screen

'Copyright (c) 1987 Ethan Winer


DEFINT A-Z

DECLARE FUNCTION ArraySize% (ULRow, ULCol, LRRow, LRCol)
DECLARE SUB Pause (Ticks)
DECLARE SUB ScrnSave (ULRow, ULCol, LRRow, LRCol, SEG Addr, Page)
DECLARE SUB ScrnRest (ULRow, ULCol, LRRow, LRCol, SEG Addr, Page)

ULRow = 10: ULCol = 30: LRRow = 15: LRCol = 50  'corners of saved window
DIM Array(ArraySize%(ULRow, ULCol, LRRow, LRCol))

CLS
COLOR 2
FOR X = 1 TO 24
    PRINT STRING$(80, X + 96);          'display test pattern
NEXT

COLOR 7
LOCATE 25, 1, 1
PRINT "Press a key: ";
CALL WaitKey

ScrnSave ULRow, ULCol, LRRow, LRCol, Array(0), Page
CLS
LOCATE 25, 1, 1
PRINT "Do it again: ";
CALL WaitKey
CLS
ScrnRest ULRow, ULCol, LRRow, LRCol, Array(0), Page

ScrnRest 1, 1, 6, 21, Array(0), Page
ScrnRest 1, 60, 6, 80, Array(0), Page
ScrnRest 19, 1, 24, 21, Array(0), Page
ScrnRest 19, 60, 24, 80, Array(0), Page

