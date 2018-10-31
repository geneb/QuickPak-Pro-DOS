'********** MPRest.Bas - demonstration for MPRest.Asm

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z
DECLARE SUB MScrnSave (ULRow, ULCol, LRRow, LRCol, SEG Addr)
DECLARE SUB MScrnRest (ULRow, ULCol, LRRow, LRCol, SEG Addr)
DECLARE SUB MPRestore (ULRow, ULCol, LRRow, LRCol, Original, SEG Addr)

ULRow = 10: ULCol = 1: LRRow = 20: LRCol = 80  'corners of saved window
Page = -1
Wide = 80

REDIM Array(2000)

WIDTH Wide
SCREEN 0, 0, 0, 0
CLS
COLOR 2

FOR X = 1 TO 24
    PRINT STRING$(Wide, X + 96);          'display test pattern
NEXT

COLOR 7
LOCATE 25, 1, 1
PRINT "Press a key: ";
WHILE INKEY$ = "": WEND

MScrnSave ULRow, ULCol, LRRow, LRCol, Array(0)
CLS
LOCATE 25, 1, 1
PRINT "Do it again: ";
WHILE INKEY$ = "": WEND
CLS
MScrnRest ULRow, ULCol, LRRow, LRCol, Array(0)
MPRestore 2, 3, 7, 12, 80, Array(310)

