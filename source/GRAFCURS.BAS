'********** GrafCurs.Bas - demonstrates the QuickPak Professional GrafCursor
' routine, which defines the shape of the graphics mouse cursor

'Copyright (c) 1991 Phil Cramer, with thanks to Ethan Winer and Harald Zoschke


'IMPORTANT NOTE:  Before any of the QuickPak Professional mouse routines
'will operate, you MUST first call InitMouse, as shown in this example.

DEFINT A-Z

DECLARE SUB ButtonPress (Button, Status, Count, X, Y)
DECLARE SUB GetCursor (X, Y, Button)
DECLARE SUB GrafCursor (X, Y, Cursor$)
DECLARE SUB HideCursor ()
DECLARE SUB Motion (Sensitivity)
DECLARE SUB ShowCursor ()

DECLARE FUNCTION Bin2Num% (Binary$)
DECLARE FUNCTION Monitor%
DECLARE FUNCTION Peek1% (Segment, Address)

GOSUB SetUpScreen                       'Determine screen mode, draw screen

CALL InitMouse(There)                   'Initialize and see if mouse installed
IF NOT There THEN
   SCREEN 0
   PRINT "No mouse is installed"
   END
END IF
ShowCursor                              'Turn on the mouse cursor

LOCATE 2, 47: PRINT "Defining cursors, please wait..."

DIM MouseCursor$(4)                     'Dim an array to hold the cursor defs

IF Colr THEN                            'If color monitor, load custom cursor
  FOR I = 0 TO 4                        'Defining 5 cursors, execute 5 times
    MouseCursor$(I) = STRING$(64, 255)  'Read the cursor definition
    FOR X = 1 TO 64 STEP 2
      READ X$
      H& = Bin2Num%(X$)
      MID$(MouseCursor$(I), X) = CHR$(H& AND 255)'isolate the lo-byte
      H& = H& AND &HFF00                         'ditto for the hi-byte
      IF H& < 0 THEN H& = H& + 65536             'some numbers may be negative
      H& = H& / 256                              'shift bits right 8 places
      MID$(MouseCursor$(I), X + 1) = CHR$(H&)
    NEXT
  NEXT
END IF

LOCATE 2, 47: PRINT SPACE$(32)          'Erase the message

Sensitivity = 90
CALL Motion(101 - Sensitivity)          'Set mouse sensitivity

DO
  GetCursor X, Y, Button                'Get cursor location

  SELECT CASE X

    CASE IS > XCenter
      IF Y > YCenter THEN               'Lower right quadrant
	IF Cursr <> 0 THEN GrafCursor 4, 1, MouseCursor$(0)
	Cursr = 0
      ELSEIF Y > YLine THEN             'Upper right quadrant
	IF Cursr <> 1 THEN GrafCursor 8, 7, MouseCursor$(1)
	Cursr = 1
      ELSE                              'Top 2 rows
	IF Cursr <> 4 THEN GrafCursor 4, 2, MouseCursor$(4)
	Cursr = 4
      END IF

    CASE ELSE
      IF Y > YCenter THEN               'Lower left quadrant
	IF Cursr <> 2 THEN GrafCursor 7, 7, MouseCursor$(2)
	Cursr = 2
      ELSEIF Y > YLine THEN             'Upper left quadrant
	IF Cursr <> 3 THEN GrafCursor 7, 7, MouseCursor$(3)
	Cursr = 3
      ELSE                              'Top 2 rows
	IF Cursr <> 4 THEN GrafCursor 4, 2, MouseCursor$(4)
	Cursr = 4'                    ^  ^
      END IF     '                    ³  ÀÄ Mouse y hotspot
		 '                    ÀÄÄÄÄ Mouse x hotspot
  END SELECT

  Ky$ = INKEY$                          'Look for key presses
  IF LEN(Ky$) THEN
    SELECT CASE ASC(Ky$)

      CASE 43       '+                  '"+" increase sensitivity
	Sensitivity = Sensitivity + 1
	IF Sensitivity > 100 THEN Sensitivity = 100
	CALL Motion(101 - Sensitivity)
	LOCATE 2, 30: PRINT Sensitivity; "  ";

      CASE 45       '-                  '"-" decrease sensitivity
	Sensitivity = Sensitivity - 1
	IF Sensitivity < 1 THEN Sensitivity = 1
	CALL Motion(101 - Sensitivity)
	LOCATE 2, 30: PRINT Sensitivity; "  ";

      CASE ELSE
	'this is needed for QB 4.0 compatibility
    END SELECT
  END IF

LOOP UNTIL Ky$ = CHR$(27) OR Button > 1    'Wait for Escape, right click

HideCursor                                 'Turn off the mouse cursor

CLS
Button = 1
CALL ButtonPress(Button, 0, Count, 0, 0)
PRINT "During this demo you pressed button One"; Count;
PRINT "time";
IF Count = 0 OR Count > 1 THEN PRINT "s";       'this is getting rather
						'  picky, wouldn't you say?
PRINT ", and button Two";
CALL ButtonPress(2, 0, Count, 0, 0)
PRINT Count; "time";
IF Count = 0 OR Count > 1 THEN PRINT "s";
PRINT "."
PRINT "Press any key..."

CALL WaitKey            'pause for a key press

SCREEN 0                'reset the screen to text mode

'---- Notes about defining the mouse cursor shape
'The first group of binary data is the screen mask.
'The second group of binary data is the cursor mask.
'The cursor color is black where both masks are 0.
'The cursor color is XORed where both masks are 1.
'The color is clear where the screen mask is 1 and the cursor mask is 0.
'The color is white where the screen mask is 0 and the cursor mask is 1.

'InverseArrow
'--- this is the screen mask
DATA "1110011111111111"
DATA "1110001111111111"
DATA "1110000111111111"
DATA "1110000011111111"
DATA "1110000001111111"
DATA "1110000000111111"
DATA "1110000000011111"
DATA "1110000000001111"
DATA "1110000000000111"
DATA "1110000000000011"
DATA "1110000000000001"
DATA "1110000000011111"
DATA "1110001000011111"
DATA "1111111100001111"
DATA "1111111100001111"
DATA "1111111110001111"

'---- this is the cursor mask
DATA "0001100000000000"
DATA "0001010000000000"
DATA "0001001000000000"
DATA "0001000100000000"
DATA "0001000010000000"
DATA "0001000001000000"
DATA "0001000000100000"
DATA "0001000000010000"
DATA "0001000000001000"
DATA "0001000000000100"
DATA "0001000000111110"
DATA "0001001100100000"
DATA "0001110100100000"
DATA "0000000010010000"
DATA "0000000010010000"
DATA "0000000001110000"

'Crosshair 1
DATA "1111111000111111"
DATA "1111111000111111"
DATA "1110000000000011"
DATA "1110000000000011"
DATA "1110000000000011"
DATA "1110001101100011"
DATA "1000001111100000"
DATA "1000000111000000"
DATA "1000001111100000"
DATA "1110001101100011"
DATA "1110000000000011"
DATA "1110000000000011"
DATA "1110000000000011"
DATA "1111111000111111"
DATA "1111111000111111"
DATA "1111111111111111"

DATA "0000000000000000"
DATA "0000000010000000"
DATA "0000000010000000"
DATA "0000111111111000"
DATA "0000100010001000"
DATA "0000100010001000"
DATA "0000100000001000"
DATA "0011111000111110"
DATA "0000100000001000"
DATA "0000100010001000"
DATA "0000100010001000"
DATA "0000111111111000"
DATA "0000000010000000"
DATA "0000000010000000"
DATA "0000000000000000"
DATA "0000000000000000"

'Hour Glass
DATA "1100000000000111"
DATA "1100000000000111"
DATA "1100000000000111"
DATA "1110000000001111"
DATA "1110000000001111"
DATA "1111000000011111"
DATA "1111100000111111"
DATA "1111110001111111"
DATA "1111110001111111"
DATA "1111100000111111"
DATA "1111000000011111"
DATA "1110000000001111"
DATA "1110000000001111"
DATA "1100000000000111"
DATA "1100000000000111"
DATA "1100000000000111"

DATA "0000000000000000"
DATA "0001111111110000"
DATA "0000000000000000"
DATA "0000111111100000"
DATA "0000100110100000"
DATA "0000010001000000"
DATA "0000001010000000"
DATA "0000000100000000"
DATA "0000000100000000"
DATA "0000001010000000"
DATA "0000011111000000"
DATA "0000110001100000"
DATA "0000100000100000"
DATA "0000000000000000"
DATA "0001111111110000"
DATA "0000000000000000"

'Crosshair 2
DATA "1111110001111111"
DATA "1111110001111111"
DATA "1111110001111111"
DATA "1111110001111111"
DATA "1111110001111111"
DATA "1111110001111111"
DATA "0000000000000001"
DATA "0000000100000001"
DATA "0000000000000001"
DATA "1111110001111111"
DATA "1111110001111111"
DATA "1111110001111111"
DATA "1111110001111111"
DATA "1111110001111111"
DATA "1111110001111111"
DATA "1111111111111111"

DATA "0000000000000000"
DATA "0000000100000000"
DATA "0000000100000000"
DATA "0000000100000000"
DATA "0000000100000000"
DATA "0000000100000000"
DATA "0000000100000000"
DATA "0111111111111100"
DATA "0000000100000000"
DATA "0000000100000000"
DATA "0000000100000000"
DATA "0000000100000000"
DATA "0000000100000000"
DATA "0000000100000000"
DATA "0000000000000000"
DATA "0000000000000000"

'Standard Arrow
'--- this is the screen mask
DATA "1110011111111111"
DATA "1110001111111111"
DATA "1110000111111111"
DATA "1110000011111111"
DATA "1110000001111111"
DATA "1110000000111111"
DATA "1110000000011111"
DATA "1110000000001111"
DATA "1110000000000111"
DATA "1110000000000011"
DATA "1110000000111111"
DATA "1110001000011111"
DATA "1110011000011111"
DATA "1111111100001111"
DATA "1111111100001111"
DATA "1111111110001111"

'---- this is the cursor mask
DATA "0000000000000000"
DATA "0000100000000000"
DATA "0000110000000000"
DATA "0000111000000000"
DATA "0000111100000000"
DATA "0000111110000000"
DATA "0000111111000000"
DATA "0000111111100000"
DATA "0000111111110000"
DATA "0000111110000000"
DATA "0000110110000000"
DATA "0000100011000000"
DATA "0000000011000000"
DATA "0000000001100000"
DATA "0000000001100000"
DATA "0000000000000000"



END

SetUpScreen:

IF Peek1%(0, &H463) <> &HB4 THEN       'it's color
  Colr = -1                            'set the color flag for later
  
  SELECT CASE Monitor%                 'see what screen mode to use

    CASE 2                    'Hercules
      SCREEN 3
      XWide = 720
      YHite = 348
      XCenter = 360
      YCenter = 174
      YLine = 28
      BGClr = 0

    CASE 3, 8, 9, 10          'CGA
      SCREEN 2
      XWide = 640
      YHite = 200
      XCenter = 320
      YCenter = 100
      YLine = 16
      BGClr = 0

    CASE 5                    'EGA
      SCREEN 9
      XWide = 640
      YHite = 350
      XCenter = 320
      YCenter = 175
      YLine = 28
      BGClr = 1

    CASE 7, 12                'VGA
      SCREEN 12
      XWide = 640
      YHite = 480
      XCenter = 320
      YCenter = 240
      YLine = 32
      BGClr = 1

    CASE ELSE
  END SELECT
END IF

LINE (0, 0)-(XWide - 1, YHite - 1), BGClr, BF  'Draw the background and
LINE (0, YCenter)-(XWide - 1, YCenter)         ' divide it into quadrants
LINE (XCenter, 0)-(XCenter, YHite - 1)

LOCATE 1, 1: PRINT " Press + to increase mouse sensitivity, - to decrease                           "
LOCATE 2, 1: PRINT " Mouse Sensitivity(1 - 100):  90                                                "
LINE (0, YLine)-(XWide - 1, YLine)
LINE (0, 0)-(XWide - 1, YHite - 1), , B

RETURN

