'********* PARSESTR.BAS - demonstrates the ParseString function

'Copyright (c) 1991 Ethan Winer


DEFINT A-Z
DECLARE FUNCTION ParseString$ (CurPos, Work$, Delimit$)

CurPos = 1
Work$ = ENVIRON$("PATH")
Delimit$ = ";,/-+"

CLS
PRINT "PATH being parsed ==> "; Work$
PRINT

PRINT "CurPos  Parsed items"
PRINT "------  ------------"

DO
  PRINT USING "####"; CurPos;
  ThisItem$ = ParseString$(CurPos, Work$, Delimit$)
  PRINT TAB(9); ThisItem$
LOOP WHILE CurPos <= LEN(Work$)

