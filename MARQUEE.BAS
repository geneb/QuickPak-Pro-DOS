'********** Marquee.Bas

'demonstrates a cute way to display a message while waiting for a key press

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z
DECLARE SUB Marquee (Message$, Row, Colr)
DECLARE SUB Pause (Ticks)
DECLARE SUB QPrint (X$, Colr, Page)

CLS
Message$ = "This is a scrolling message . . . "
PRINT "Press a key when you feel like it"
PRINT

DO
   X$ = INKEY$
   Marquee Message$, 24, 112    'do it on row 24 in black on white
LOOP UNTIL LEN(X$)
  
PRINT "You pressed "; CHR$(34); X$; CHR$(34)

SUB Marquee (X$, Row%, Colr%) STATIC

    STATIC P%                   'remembers the current position between calls

    H% = POS(0)                 'save the current cursor position
    V% = CSRLIN
    L% = LEN(X$)                'we need to know the length

    P% = P% + 1                 'advance to the next character
    IF P% > L% THEN P% = 1      'wrap around at the end

    LOCATE Row%, 40 - L% \ 2
    QPrint RIGHT$(X$, L% - P% + 1) + LEFT$(X$, P% - 1), Colr%, -1

    Pause (2)                   'pause a bit to slow down the scrolling
    LOCATE V%, H%               'restore the cursor position

END SUB

