'***** MRANGE.BAS - demo for MouseRange assembler routine
'
'written by Jay Munro
'Copyright (c) 1989 Crescent Software

DEFINT A-Z
DECLARE FUNCTION Peek1% (Segment, Offset)   'to check monitor type

CLS
CALL Initmouse(There)                   'mouse initializing stuff
IF NOT There THEN                       'no mouse installed
   BEEP                                 'let them know                      
   PRINT "No mouse is installed, ending."
   END
END IF

FG = 0                                  'initialize mouse cursor colors
BG = 7                                  'these are for monochrome monitors

IF Peek1%(0, &H463) <> &HB4 THEN        'if a color monitor, then set colors
   FG = -2                              'for reverse of color cursor is over
   BG = -2
END IF

CALL TextCursor(FG, BG)                 'set up our text cursor
COLOR 0, 7                              'color for status box

TYPE Area                               'mouse range area structure
  Ulr AS INTEGER                        'this could be done with
  Ulc AS INTEGER                        'a normal integer array, but
  Lrr AS INTEGER                        'this is much easier to follow
  Lrc AS INTEGER
  RNum AS INTEGER                       'range number (see the manual)
END TYPE
REDIM MCoord(1 TO 8) AS Area

LOCATE 1, 20                               'print the status box
PRINT "M-Row", "M-Col", "Button", "Box";   'print the return parameters
LOCATE 25, 2
PRINT "Press button 1 in a colored box to see the action, press button 2 to end.";

    FOR X = 1 TO 8                      'get some data into it
        READ MCoord(X).Ulr              'upper corners
        READ MCoord(X).Ulc
        READ MCoord(X).Lrr              'lower corners
        READ MCoord(X).Lrc
        READ MCoord(X).RNum             'area number

'=== if there's a color display use PaintBox to color the boxes
        IF FG THEN CALL MPaintbox(MCoord(X).Ulr, MCoord(X).Ulc, MCoord(X).Lrr, MCoord(X).Lrc, 16 * X)
        CALL Box0(MCoord(X).Ulr, MCoord(X).Ulc, MCoord(X).Lrr, MCoord(X).Lrc, 1, -1)
        LOCATE MCoord(X).Ulr, MCoord(X).Ulc, 0
        PRINT MCoord(X).RNum;           'print the box number
        CALL Pause(3)                   'pause for effect. . .
     NEXT X
   
    CALL ShowCursor

'=== loop here until button 2 is pressed
    WHILE Button < 2
       CALL MouseRange(SEG MCoord(1), 8, RetRow, RetCol, Button, Range)
       LOCATE 2, 20
       PRINT RetRow, RetCol, Button, Range;
    WEND

'=== if we got a valid range number then do some theatrics                          
    IF Range THEN
       CALL HideCursor                     'hide cursor for this print
       CALL Box0(MCoord(Range).Ulr, MCoord(Range).Ulc, MCoord(Range).Lrr, MCoord(Range).Lrc, 1, 15 OR 128)
       LOCATE 24, 45
       PRINT "You Picked box number"; Range;
       CALL ShowCursor                     'restore cursor
    END IF
    COLOR 7, 0
    CALL HideCursor
    END

'=============================== Range Data areas ===========================
'    ULR  ULC  LRR  LRC  RNum
DATA  1,   1,  10,  10,  1
DATA  4,   3,  17,  27,  2
DATA  5,  40,  18,  72,  3
DATA 15,  20,  22,  64,  4
DATA 19,  30,  24,  40,  5
DATA 13,  50,  20,  60,  6
DATA  7,  15,   9,  50,  7
DATA 10,  55,  15,  63,  8

