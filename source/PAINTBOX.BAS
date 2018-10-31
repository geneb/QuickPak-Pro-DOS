'********** PaintBox.Bas - allows painting screen colors without reprinting

'Copyright (c) 1987 Ethan Winer


DEFINT A-Z
DECLARE SUB PaintBox (ULRow, ULCol, LRRow, LRCol, Colr, Page)

DEF FnColors (FG, BG) = (FG AND 16) * 8 + (BG * 16) + (FG AND 15)

CLS
COLOR 7, 0              'color to use for printing test pattern
Colr = FnColors(9, 4)   'color to use for PaintBox

UL.Row = 7: UL.Col = 20
LR.Row = 16: LR.Col = 60
Page = -1

FOR X = 1 TO 22
    PRINT STRING$(80, "X");             'display test pattern
NEXT

PRINT
PRINT "Press a key ";
LOCATE , , 1
WHILE INKEY$ = "": WEND

PaintBox UL.Row, UL.Col, LR.Row, LR.Col, Colr, Page

