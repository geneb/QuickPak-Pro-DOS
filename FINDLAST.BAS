'********** FindLast.Bas - demonstrates FindLast

DEFINT A-Z
DECLARE FUNCTION FindLast% (BYVAL Address, Size)

CLS
Size = 10000
REDIM Array$(Size)
Array$(1) = "Errr, duh, what's up Doc?"
D! = TIMER
X = FindLast%(VARPTR(Array$(Size)), Size)
D2! = TIMER
PRINT USING "The last non-blank element is #_, and it took #.## seconds to find."; X, D2! - D!

