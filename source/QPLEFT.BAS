'********* QPLeft.Bas - demonstrates QPLeft$, QPRight$, and QPMid$

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z

DECLARE FUNCTION QPMid$ (X$, MidArg%, NumChars%)
DECLARE FUNCTION QPLeft$ (X$, LeftArg%)
DECLARE FUNCTION QPRight$ (X$, RightArg%)

CLS
X$ = "This is a very silly sort of test"
Arg = 2

PRINT "{"; X$; "}"
PRINT "{"; QPLeft$(X$, Arg); "}"
PRINT "{"; QPRight$(X$, Arg); "}"
PRINT "{"; QPMid$(X$, Arg, -1); "}"     'a negative value means take all of
                                        'the characters through the end

