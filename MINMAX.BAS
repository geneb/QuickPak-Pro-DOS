'********** MinMax.Bas - tests the Min and Max functions

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z
DECLARE FUNCTION MaxI% (SEG Element%, NumEls)
DECLARE FUNCTION MinI% (SEG Element%, NumEls)
DECLARE FUNCTION MaxL& (SEG Element&, NumEls)
DECLARE FUNCTION MinL& (SEG Element&, NumEls)
DECLARE FUNCTION MaxS! (SEG Element!, NumEls)
DECLARE FUNCTION MinS! (SEG Element!, NumEls)
DECLARE FUNCTION MaxD# (SEG Element#, NumEls)
DECLARE FUNCTION MinD# (SEG Element#, NumEls)

CLS
REDIM Array#(1 TO 10000) 'you must start QuickBASIC with /AH to run this demo

Array#(3) = 17                          'assign some test values
Array#(101) = 9000987.45321#
Array#(100) = 9000987.452099999#
Array#(10000) = -12049875643.0876#

T! = TIMER                              'time how fast MinD is
Smallest# = MinD#(Array#(1), 10000)
T1! = TIMER

PRINT "The smallest value is "; Smallest#
PRINT USING "##.### seconds to scan 80,000 bytes"; T1! - T!

