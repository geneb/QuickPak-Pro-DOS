'********** GetDir.Bas - retrieves the current drive/directory

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z
DECLARE FUNCTION GetDir$ (Drive$)
DECLARE FUNCTION GetDrive%

CLS
PRINT "Which drive (press ENTER for default drive): ";
LOCATE , , 1

DO
    Drive$ = INKEY$
LOOP UNTIL LEN(Drive$)
IF Drive$ = CHR$(13) THEN Drive$ = ""       'null means use default drive

PRINT : PRINT
PRINT "The current directory is ";

IF LEN(Drive$) THEN
   PRINT UCASE$(Drive$);        'drive was specified, print it
ELSE
   PRINT CHR$(GetDrive%);       'print the current drive as part of the path
END IF

PRINT ":"; GetDir$(Drive$)

