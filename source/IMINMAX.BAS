'********** IMinMax.Bas - tests the IMin and IMax functions

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z
DECLARE FUNCTION IMaxI% (SEG Element%, NumEls)
DECLARE FUNCTION IMinI% (SEG Element%, NumEls)
DECLARE FUNCTION IMaxL% (SEG Element&, NumEls)
DECLARE FUNCTION IMinL% (SEG Element&, NumEls)
DECLARE FUNCTION IMaxS% (SEG Element!, NumEls)
DECLARE FUNCTION IMinS% (SEG Element!, NumEls)
DECLARE FUNCTION IMaxD% (SEG Element#, NumEls)
DECLARE FUNCTION IMinD% (SEG Element#, NumEls)

CLS
NumEls = 10000
REDIM Array#(1 TO NumEls)

Array#(3) = 17
Array#(101) = 9000987.45321#
Array#(100) = 9000987.452099999#
Array#(NumEls) = -12049875643.0876#

T! = TIMER
X = IMaxD%(Array#(1), NumEls)
T1! = TIMER

'----- IMaxD returns how many elements it searched, so we need the fudge
'      below if the array doesn't start at element zero
X = X + LBOUND(Array#, 1)

PRINT "The largest value is in element"; X; "="; Array#(X)
PRINT USING "It took #.### seconds to scan 80,000 bytes"; T1! - T!

