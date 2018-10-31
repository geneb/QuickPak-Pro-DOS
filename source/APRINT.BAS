'********** APRINT.BAS - quick prints a "Mid" portion of an entire array

'Copyright (c) 1987 Ethan Winer

    DEFINT A-Z

    DECLARE SUB APrint (BYVAL A, B, C, D, E, F)
    DECLARE SUB Box (ULRow, ULCol, LRRow, LRCol, Style, Colr, Page)
    DECLARE SUB QPrint (X$, Colr, Page)

    Pages = 7   'use 3 or 7 to establish the vertical resolution of the demo
    Wide = 80   'set to 40 or 80

    Start = 1: MidFirst = 1     'start with first character in first element

    'init screens to different colors to test the default color ability
    'of APrint and Box - the Page parameters can also be hard-coded.

    IF Pages = 7 THEN   'if we're allowing 7 pages, then do 25 lines
       ScrSize = 25
       NumEls = 22
    ELSE                'otherwise use the 43 line mode (EGA only)
       ScrSize = 43
       NumEls = 40
    END IF

    IF Wide = 40 THEN   'if we're working in 40 columns, use 38 characters
       NumChars = 38
    ELSE                'otherwise use 80 characters
       NumChars = 78
    END IF

    WIDTH Wide, ScrSize
    FOR X = Pages TO 0 STEP -1
	SCREEN 0, 0, X, X
	READ FG, BG
	COLOR FG, BG
	CLS
	Box 1, 1, NumEls + 2, NumChars + 2, 3, FG + 1 + BG + 1 * 4, -1
    NEXT
    DATA 15,4,  1,0,  12,5,  2,8,  11,2,  9,0,  13,4,  14,1

    DIM Array$(2000)
    OPEN "APrint.Bas" FOR INPUT AS #1
    WHILE NOT EOF(1)
	Count = Count + 1
	LINE INPUT #1, Array$(Count)
    WEND
    CLOSE

NewPage:
    SCREEN , , Page, Page
    P$ = "Page" + STR$(Page) + ": Use arrows, "
    P$ = P$ + CHR$(34) + "P" + CHR$(34) + ", or Esc to exit"
    LOCATE NumEls + 3, 1
    QPrint P$, -1, -1

Doit:
    LOCATE 2, 2: Clr = 7
    APrint VARPTR(Array$(Start)), NumEls, MidFirst, NumChars, -1, -1

GetK:
    DO
       X$ = INKEY$
    LOOP UNTIL LEN(X$)

    IF X$ = CHR$(27) THEN END                   'Escape

    IF X$ = CHR$(0) + CHR$(80) THEN
       IF Start + NumEls - 1 > Count GOTO GetK  'Down arrow
       Start = Start + 1
       GOTO Doit
    ELSEIF X$ = CHR$(0) + CHR$(72) THEN         'Up arrow
       IF Start < 2 GOTO GetK
       Start = Start - 1
       GOTO Doit
    ELSEIF X$ = CHR$(0) + CHR$(75) THEN         'Left arrow
       IF MidFirst < 2 GOTO GetK
       MidFirst = MidFirst - 1
       GOTO Doit
    ELSEIF X$ = CHR$(0) + CHR$(77) THEN         'Right Arrow
       MidFirst = MidFirst + 1
       GOTO Doit
    ELSEIF X$ = CHR$(0) + CHR$(71) THEN         'Home key
       Start = 1
       MidFirst = 1
       GOTO Doit
    ELSEIF UCASE$(X$) = "P" THEN                'new Page
       Page = Page + 1
       IF Page > Pages THEN Page = 0
       GOTO NewPage
    END IF

    GOTO GetK

