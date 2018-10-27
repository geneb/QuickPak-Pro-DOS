'********** ClEARSCR.BAS - clears a portion of the display screen

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z

DECLARE SUB ClearScr (ULRow, ULCol, LRRow, LRCol, Colr, Page)

'WIDTH 80, 43               'for testing
'SCREEN 0, 0, 2, 2

CLS
Colr = 1 * 16               'clear to blue background (underlined if mono)
COLOR 2                     'print test pattern in green

ULRow = 10                  'portion of screen to clear
ULCol = 20
LRRow = 18
LRCol = 60
Page = -1                   'do it on the current display page

FOR X = 1 TO 24
    PRINT STRING$(80, X + 96);          'display test pattern
NEXT

LOCATE 25, 1, 1
PRINT "Press a key to see the show";
WHILE INKEY$ = "": WEND

CALL ClearScr(ULRow, ULCol, LRRow, LRCol, Colr, Page)

