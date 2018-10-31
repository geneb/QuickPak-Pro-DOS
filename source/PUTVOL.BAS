'********** PutVol.Bas - adds or replaces a volume label on a specified drive

'Copyright (c) 1987 Ethan Winer


DEFINT A-Z
DECLARE FUNCTION GetVol$ (Drive$)
DECLARE SUB PutVol (Drive$, Volume$)

CLS
PRINT "Which Drive?"
PRINT "(Press ENTER for default drive) ";
LOCATE , , 1

WHILE Drive$ = "": Drive$ = INKEY$: WEND
IF Drive$ = CHR$(13) THEN Drive$ = ""        'null string means use
PRINT : PRINT                                '  default drive

PRINT "The current label is "; GetVol$(Drive$)
PRINT

LINE INPUT "Enter the new label name: ", Volume$
PutVol Drive$, Volume$

