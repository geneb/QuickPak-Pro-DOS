'********* QPTrim.Bas - demonstrates QPLTrim$, QPRTrim$, and QPTrim$

'Copyright (c) 1988 Ethan Winer

DEFINT A-Z

DECLARE FUNCTION QPLTrim$ (X$)
DECLARE FUNCTION QPRTrim$ (X$)
DECLARE FUNCTION QPTrim$ (X$)

CLS
Zero$ = STRING$(5, 0)
X$ = Zero$ + "    This is a very silly sort of test       " + Zero$

PRINT "Original ===> {"; X$; "}"
PRINT "QPLTrim  ===> {"; QPLTrim$(X$); "}"
PRINT "QPRTrim  ===> {"; QPRTrim$(X$); "}"
PRINT "QPTrim   ===> {"; QPTrim$(X$); "}"

