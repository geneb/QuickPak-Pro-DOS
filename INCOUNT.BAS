'********* InCount.Bas - counts number of occurrences of one string in another

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z

DECLARE FUNCTION InCount2% (Source$, Search$)   'InCount% is case-sensitive

CLS
Source$ = "This tests the number of times a test string is found by testing."
Search$ = "TEST"

Count = InCount2%(Source$, Search$)
PRINT CHR$(34); Search$; CHR$(34); " occurs"; Count; "time(s) within "
PRINT CHR$(34); Source$; CHR$(34)

