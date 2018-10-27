'DemoRK.Bas - demonstrates hardware interrupt handling from within QuickBASIC

'written by Robert J. Karp

'NOTE: Contrary to the printed manual, you can safely run this demo and also
'use the Clock and Clock24 routines safely in the BASIC editing environment.


DEFINT A-Z
DECLARE SUB Clock (Row, Column, Colr, Install)
DECLARE SUB Keyboard (Row, Column, Color1, Color2, Install)
DECLARE SUB Dec2Bin (Row, Column)

'A binary conversion routine is the medium for showing this technique.

Binary$ = "The binary value of ##### is ################."
Number! = -1
COLOR 7, 0: WIDTH 80: CLS



'If you are using both routines, always install Keyboard first, then Clock.

Keyboard 25, 61, 7, 112, 1      'row, col, off color, on color, install
Clock 1, 7, 7, 1                'row, col, display color, install
Dec2Bin 1, 1                    'the vehicle for this demo

CLS

Number! = -1
Keyboard 1, 1, 7, 112, 1        'calling a second time sets new loc and color
Clock 1, 70, 15, 1
Dec2Bin 1, 64

Clock 1, 1, 0, 0                'uninstall in the reverse order
Keyboard 1, 1, 0, 0, 0

CLS

SUB Dec2Bin (Row, Column) STATIC

SHARED Binary$, Number!

LOCATE Row, Column
PRINT "Time: "
PRINT
PRINT "DECIMAL TO BINARY CONVERSION"
PRINT
PRINT "Enter a number from 1 to 65535 or 0 to end: "

WHILE Number! <> 0
    LOCATE 5, 45
    PRINT SPACE$(35)
    LOCATE 5, 45
    LINE INPUT "", Number$
    IF VAL(Number$) >= 0 AND VAL(Number$) < 65536 THEN
	Number! = INT(VAL(Number$))
	temp! = Number!
	FOR i = 15 TO 0 STEP -1
	    IF temp! < 2 ^ i THEN
		MID$(Binary$, (45 - i)) = "0"
	    ELSE
		MID$(Binary$, (45 - i)) = "1"
		temp! = temp! - 2 ^ i
	    END IF
	NEXT
	LOCATE 7, 1
	PRINT USING Binary$; Number!
    END IF
WEND

END SUB

