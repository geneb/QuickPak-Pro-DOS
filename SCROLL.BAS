'********** Scroll.Bas - demonstrates the four QuickPak scroll routines

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z
DECLARE SUB ScrollU (ULRow, ULCol, LRRow, LRCol, Lines, Page)
DECLARE SUB ScrollD (ULRow, ULCol, LRRow, LRCol, Lines, Page)
DECLARE SUB ScrollL (ULRow, ULCol, LRRow, LRCol, Lines, Page)
DECLARE SUB ScrollR (ULRow, ULCol, LRRow, LRCol, Lines, Page)

Wide = 80
High = 25
Lines = 4
Page = -1

ULRow = 7
ULCol = Wide \ 8
LRRow = 16
LRCol = Wide - Wide \ 8

CLS
COLOR 7, 4
FOR X = 1 TO High - 3
    PRINT STRING$(Wide, X + 32);        'display test pattern
NEXT

PRINT
PRINT
COLOR 2, 0
PRINT "Scroll Up or Down? ";
LOCATE , , 1

DO
   X$ = INKEY$
LOOP UNTIL LEN(X$)

IF UCASE$(X$) = "U" THEN
   ScrollU ULRow, ULCol, LRRow, LRCol, Lines, Page
ELSE
   ScrollD ULRow, ULCol, LRRow, LRCol, Lines, Page
END IF

LOCATE , 1
PRINT "Press any key to continue ";
CALL WaitKey

COLOR 7
CLS
COLOR , 4
Test$ = SPACE$(Wide)

FOR X = 1 TO Wide
    MID$(Test$, X, 1) = CHR$(X + 32)
NEXT
FOR X = 1 TO High - 3
    PRINT Test$;
NEXT

PRINT
PRINT
COLOR 2, 0
PRINT "Scroll Left or Right? ";

DO
   X$ = INKEY$
LOOP UNTIL LEN(X$)

IF UCASE$(X$) = "L" THEN
   ScrollL ULRow, ULCol, LRRow, LRCol, Lines, Page
ELSE
   ScrollR ULRow, ULCol, LRRow, LRCol, Lines, Page
END IF

