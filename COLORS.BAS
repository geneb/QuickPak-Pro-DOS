'******** COLORS.BAS - prints a chart of the screen attributes for each color

'Copyright (c) 1988 Ethan Winer


'This chart provides a quick reference to the various "encoded" colors
'that are used with QPrint, APrint, and the other QuickPak video routines.
'To get a hard copy printout, press Shift-PrtSc once it is on your screen.

DEFINT A-Z
DECLARE FUNCTION OneColor% (FG, BG)
DECLARE FUNCTION Peek1% (Segment, Address)

CLS
IF Peek1%(0, &H463) <> &HB4 THEN ColorMon = 1   'see what monitor is active
DEF FnPad$ (X$) = SPACE$((7 - LEN(X$)) / 2) + X$      'for centering
Mask$ = "  ###  "                                     'for Print Using

DIM Colr$(8)                                            'the color names
FOR X = 0 TO 8
    READ Colr$(X)
NEXT
DATA Black, Blue, Green, Cyan, Red, Magenta, Brown, White, Gray

LOCATE 2, 23
COLOR 9
PRINT "  Crescent Software Color Chart  "

FOR BG = 0 TO 7

    LOCATE 5, 15 + BG * 8
    COLOR 7, 0
    PRINT FnPad$(Colr$(BG))

    FOR FG = 0 TO 15

	LOCATE 7 + FG, 1
	COLOR 7, 0
	IF FG <= 8 THEN
	   PRINT Colr$(FG);
	ELSE
	   PRINT "Bright "; Colr$(FG - 8);
	END IF

	LOCATE , 15 + BG * 8
	COLOR FG, BG
	PRINT USING Mask$; OneColor%(FG, BG)

    NEXT
NEXT

COLOR 7, 0: LOCATE 7, 18: PRINT 0
IF ColorMon THEN COLOR 8
LOCATE 15, 18: PRINT 8

