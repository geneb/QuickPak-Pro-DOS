'********** Replace.Bas

'replaces all occurences of one string with another without regard
'to capitalization

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z

DECLARE SUB ReplaceString (Work$, Old$, New$)
DECLARE SUB ReplaceChar (Work$, Old$, New$)
DECLARE SUB ReplaceChar2 (Work$, Old$, New$)
DECLARE FUNCTION QInstr2 (Start%, Str1$, Str2$)

CLS

Work$ = "This is a test of the Replace function in QuickPak Professional."
Old$ = "this"
New$ = "And now this"

PRINT Work$
ReplaceString Work$, Old$, New$
PRINT Work$

PRINT
Work$ = "Now let's replace only single characters at assembler speed!"
PRINT Work$
ReplaceChar Work$, "n", "m"
PRINT Work$
PRINT

Work$ = "And finally replace all characters regardless of capitalization."
PRINT Work$
ReplaceChar2 Work$, "a", "e"
PRINT Work$

SUB ReplaceString (Work$, Old$, New$) STATIC

    OldLen = LEN(Old$)
    NewLen = LEN(New$)
    Pointer = 1

Again:
    'change the QInstr2 to QInstr to make searching case sensitive
    Pointer = QInstr2%(Pointer, Work$, Old$)

    IF Pointer THEN
       Work$ = LEFT$(Work$, Pointer - 1) + New$ + MID$(Work$, Pointer + OldLen)
       Pointer = Pointer + NewLen
       GOTO Again
    END IF

END SUB

