'********* Search.Bas - demonstrates searching any type of array FAST!

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z
DECLARE SUB Search (SEG StartEl AS ANY, NumEls, Match AS ANY, Found, Direction, MatchCode, VarType)

CLS
REDIM Array#(10000)     'REDIM makes it a $Dynamic (far) array
TotalEls = 10001        'don't forget element zero

Match# = 1234           'value to find
Array#(9999) = Match#   'put it near the end of the array
StartEl = 10            'start looking near the beginning of the array
Direction = 0           '0 means forward, anything else means backward
MatchCode = 1           '0 = exact, 1 = greater or equal, -1 = less or equal
VarType = -4            '-1 = integer, -2 = long int, -3 = Sgl. Prec., -4 = DP


IF Direction = 0 THEN           'calculate how many elements to search
   NumEls = TotalEls - StartEl  '  based on the direction
ELSE
   NumEls = StartEl + 1         'this assumes the array starts at zero
END IF                          '  adjust if you start at 1 (or anything else)

X! = TIMER                      'to time the search
Search Array#(StartEl), NumEls, Match#, Found, Direction, MatchCode, VarType
X1! = TIMER

IF Found = -1 THEN              'Search returns -1 if it didn't find a match
   PRINT "Not found"
ELSE
   IF Direction = 0 THEN        'we need to know the direction, since SearchI
      Found = StartEl + Found   '  simply returns how many elements it
   ELSE                         '  examined, not the actual element number
      Found = StartEl - Found   '  it found the Match at.
   END IF
   PRINT "The value"; Match#; "was found at element number"; Found
END IF

PRINT
PRINT USING "Search took #.## seconds to scan" + STR$(CSNG(NumEls) * 8) + " bytes"; X1! - X!

