'********** Valid.Bas - brute force test to see if a file/path name is valid

'Copyright (c) 1988 Ethan Winer


'IMPORTANT NOTE: Valid does NOT tell if the file or path actually exists.
'It simply verifies that the name COULD be valid.

DEFINT A-Z
DECLARE FUNCTION Valid% (FSpec$)

CLS

More:
INPUT "Enter a file name: ", FileName$  'ask for a file name

FileName$ = LTRIM$(RTRIM$(FileName$))   'trim leading/trailing blanks
                                        '  which Valid considers illegal
IF FileName$ = "" THEN END

PRINT UCASE$(FileName$);

IF Valid(FileName$) THEN
   PRINT " is a good name."
ELSE
   PRINT " is not valid"
END IF

PRINT
GOTO More

