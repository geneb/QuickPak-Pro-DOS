'********** PrtSc.Bas - does a Print Screen on any screen page, any printer

'Copyright (c) 1987 Ethan Winer


DEFINT A-Z
DECLARE SUB PrtSc (LPTNumber, Page)
DECLARE FUNCTION ArraySize% (ULRow, ULCol, LRRow, LRCol)

LPTNumber = 1
'Page = 2               'for testing
'WIDTH 80, 43
'SCREEN 0, 0, 2, 2

CLS
PRINT TAB(27); "Print Screen Demonstration"
PRINT

FOR X = 1 TO 22                 'fill screen with test pattern
    PRINT STRING$(80, X + 96);
NEXT

PrtSc LPTNumber, Page             'do Print Screen

IF LPTNumber = -1 THEN            'if printer returns -1, there was an error
   PRINT "Printer Error!"
   PLAY "L32ECECEC"
ELSE                            'otherwise send a formfeed to specified LPT:
   OPEN "LPT" + MID$(STR$(LPTNumber), 2) + ":" FOR OUTPUT AS #1
   PRINT #1, CHR$(12);
   CLOSE
END IF



'*****************************************************************************
'
'It is also possible to print just a portion of the screen.  The example
'below has nothing to do with PrtSc, and is provided simply to show how
'this could be done.
'
'   ULRow = 5: ULCol = 10       'portion of the screen to be printed
'   LRRow = 20: LRCol = 70
'
'   FOR X = 1 TO 24             'fill screen with test pattern
'       PRINT STRING$(80, X + 96);
'   NEXT
'
'   REDIM Array(ArraySize%(ULRow, ULCol, LRRow, LRCol))
'   CALL ScrnSave(ULRow, ULCol, LRRow, LRCol, SEG Array(0), -1) 'must use
'                                                               '  element 0
'   NumCols = LRCol - ULCol + 1
'   OPEN "LPT1:" FOR OUTPUT AS #1
'   FOR X = 0 TO LRRow - ULRow
'       PRINT #1, TAB(ULCol);                   'optional to tab the printer
'       FOR Y = 0 TO LRCol - ULCol
'           Char = Array(X * NumCols + Y) MOD 256
'           PRINT #1, CHR$(Char);
'       NEXT
'       PRINT #1,
'   NEXT
'   CLOSE
'   ERASE Array
'
'*****************************************************************************

