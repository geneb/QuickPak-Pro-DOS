'********** Mouse.Bas - demonstrates the QuickPak Professional Mouse routines

'Copyright (c) 1988 Ethan Winer, with thanks to Harald Zoschke


'IMPORTANT NOTE:  Before any of the QuickPak Professional mouse routines
'will operate, you MUST first call InitMouse, as shown in this example.


DEFINT A-Z

DECLARE SUB Bin2Hex (Binary$, HexNum)
DECLARE FUNCTION Monitor%
DECLARE FUNCTION Peek1% (Segment, Address)
DECLARE SUB Prompt (Message$)
DECLARE SUB WaitButton ()
DECLARE SUB ButtonPress (Button, Status, Count, X, Y)

IF Peek1%(0, &H463) <> &HB4 THEN        'it's color
   Colr = -1                            'set the color flag for later
   SELECT CASE Monitor%                 'see what screen mode to use
      CASE 2                    'Hercules
	 SCREEN 3
      CASE 3, 8, 9, 10          'CGA
	 SCREEN 2
      CASE 5                    'EGA
	 SCREEN 9
      CASE 7, 12                'VGA
	 SCREEN 12
      CASE ELSE
   END SELECT
END IF


CLS
CALL InitMouse(There)                   'initialize and see if mouse installed
IF NOT There THEN
   SCREEN 0
   PRINT "No mouse is installed"
   END
END IF


DIM Choice$(5)                          'display some choices on the screen,
LOCATE 1, 1                             '  so we'll have something to point at
FOR X = 1 TO 5
    READ Choice$(X)
    PRINT Choice$(X);
    LOCATE , X * 12
NEXT
DATA "Choice 1", "Choice 2", "Choice 3", "Choice 4", "Choice 5"


IF Colr THEN                            'if color monitor, load custom cursor
   Arrow$ = STRING$(64, 255)            'a distinctive arrow proves it works
   FOR X = 33 TO 64 STEP 2
       READ X$
       CALL Bin2Hex(X$, H)
       MID$(Arrow$, X) = CHR$(H AND 255)        'isolate the lo-byte
       H& = H AND &HFF00                        'ditto for the hi-byte
       IF H& < 0 THEN H& = H& + 65536           'some numbers may be negative
       H& = H& / 256                            'shift bits right 8 places
       MID$(Arrow$, X + 1) = CHR$(H&)
   NEXT
   DATA "1000000000000000"        : 'using the block of code above, it is
   DATA "1110000000000000"        : '  easy to define a custom cursor
   DATA "1111100000000000"        : '  shape using binary data strings
   DATA "1111111000000000"        : '  just like these
   DATA "1101100000000000"
   DATA "0000110000000000"
   DATA "0000011000000000"
   DATA "0000001100000000"
   DATA "0000000110000000"
   DATA "0000000011000000"
   DATA "0000000001100000"
   DATA "0000000000110000"
   DATA "0000000000011000"
   DATA "0000000000001100"
   DATA "0000000000000110"
   DATA "0000000000000011"
   CALL GrafCursor(0, 0, Arrow$)        'hot spot is at 0,0 (the arrow's tip)
ELSE
   CALL TextCursor(-2, -2)              'initiate inverting text cursor
END IF


CALL ShowCursor
CALL Prompt("Point the cursor at a choice, and press either button")

Button = 0
WHILE Button = 0                        'wait for a button press
   CALL GetCursor(X, Y, Button)
WEND
IF Button AND 4 THEN Button = 3         'for three-button mice (mouses?)

CALL Prompt("You pressed button" + STR$(Button) + " and the cursor was at " + "location" + STR$(X) + "," + STR$(Y) + " - press a button")
CALL WaitButton



'----- set hour glass shape
IF Colr THEN                            'now use the hourglass shape
   Arrow$ = STRING$(64, 255)
   FOR X = 33 TO 64 STEP 2
       READ X$
       CALL Bin2Hex(X$, H)
       MID$(Arrow$, X) = CHR$(H AND 255)        'isolate the lo-byte
       H& = H AND &HFF00                        'ditto for the hi-byte
       IF H& < 0 THEN H& = H& + 65536           'some numbers may be negative
       H& = H& / 256                            'shift bits right 8 places
       MID$(Arrow$, X + 1) = CHR$(H&)
   NEXT
   DATA "0011111111111100"
   DATA "0001111111111000"
   DATA "0000111111110000"
   DATA "0000011111100000"
   DATA "0000001111000000"
   DATA "0000000110000000"
   DATA "0000000110000000"
   DATA "0000000110000000"
   DATA "0000001111000000"
   DATA "0000011111100000"
   DATA "0000111111110000"
   DATA "0001111111111000"
   DATA "0011111111111100"
   DATA "0000000000000000"
   DATA "0000000000000000"
   DATA "0000000000000000"
   CALL GrafCursor(0, 0, Arrow$)
END IF



CALL Prompt("Move the mouse around, observe its sensitivity, then press a button")
CALL Motion(1)                          'make the mouse VERY sensitive
CALL SetCursor(100, 100)                'make sure it's not out in left field
CALL WaitButton                         'BASIC routine pauses for button press

CALL Prompt("Now see how sensitive the mouse is, then press a button")
CALL Motion(100)
CALL SetCursor(100, 100)
CALL WaitButton



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

CALL WaitKey            'pause for a key press
SCREEN 0                'reset the screen to text mode

SUB Bin2Hex (Binary$, HexNum) STATIC    'converts binary strings to hex and
    Hex& = 0                            '  simplifies defining mouse cursor
    Count = 0
    FOR X = LEN(Binary$) TO 1 STEP -1
	IF MID$(Binary$, X, 1) = "1" THEN Hex& = Hex& + 2 ^ Count
	Count = Count + 1
    NEXT
    IF Hex& > 32767 THEN Hex& = Hex& - 65536
    HexNum = Hex&
END SUB

SUB Prompt (Message$) STATIC            'display a prompt message
    V = CSRLIN                          'remember the current cursor position
    H = POS(0)
    LOCATE 25, 1
    PRINT LEFT$(Message$, 79); TAB(80);
    LOCATE V, H                         'restore the cursor position
END SUB

SUB WaitButton STATIC
    X! = TIMER                          'pause a bit to give 'em a chance to
    WHILE X! + .2 > TIMER               '  release the button
    WEND

    Button = 0
    WHILE Button = 0
       CALL GetCursor(X, Y, Button)
    WEND
END SUB

