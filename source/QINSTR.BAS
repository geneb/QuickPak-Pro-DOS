'********** QInstr.Bas - tests QInstr.Asm

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z
DECLARE FUNCTION QInstr% (Start, Source$, Search$)

CLS
Start = 7
Source$ = "This is a test of the QInstr routine"
Search$ = "I???"

Position = QInstr%(Start, Source$, Search$)

PRINT Source$
IF Position THEN
   PRINT TAB(Position); Search$
   PRINT TAB(Position); MID$(STR$(Position), 2)
ELSE
   PRINT "Not Found"
END IF

