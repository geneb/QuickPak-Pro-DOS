'********** SetAttr.Bas - sets a file's attributes

'Copyright (c) 1987 Ethan Winer


DEFINT A-Z
CLS

'Attr% = 1 for Read-Only, 2 for Hidden, 32 for Archive, or 0 for No Archive

Table$ = CHR$(1) + CHR$(2) + CHR$(32) + CHR$(0) 'table of attributes

LINE INPUT "File Spec: "; F$

PRINT "Read-Only, Hidden, Archive, No Archive (R/H/A/N): ";
LOCATE , , 1

GetKey:
    X$ = INKEY$
    IF X$ = "" GOTO GetKey
    PRINT X$;

A = INSTR("RrHhAaNn", X$) / 2           'look in a list of acceptable letters
IF A = 0 GOTO GetKey                    'oops, not there - go again

Attr = ASC(MID$(Table$, A))             'specify the attribute to use from
                                        '  the table defined earlier
CALL SetAttr(F$, Attr)

IF Attr = -1 THEN                       'Attr comes back -1 if illegal
   PRINT
   PRINT "Sorry, that file doesn't exist."
END IF

