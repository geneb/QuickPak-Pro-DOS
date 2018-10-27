'********** Pause3.Bas - computes a PC's "fudge factor" for precise timings

'Copyright (c) 1989 Ethan Winer


DEFINT A-Z
DECLARE FUNCTION FudgeFactor& ()
DECLARE SUB Pause3 (Milliseconds, Fudge&)

CLS
Fudge& = FudgeFactor&   'call FudgeFactor first because it delays <= .1 second

PRINT "This PC requires a fudge factor of"; Fudge&
PRINT
INPUT "Enter the number of milliseconds to delay for: ", MSecs

T! = TIMER              'bear in mind that BASIC's timer has a resolution
Pause3 MSecs, Fudge&    '  of only 0.056 seconds, so for the most accurate
T! = TIMER - T!         '  comparison use a fairly long delay period

PRINT USING "BASIC says the delay was actually ##.### seconds"; T!

