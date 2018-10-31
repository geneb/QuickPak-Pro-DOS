'********** FULLNAME.BAS - returns a full qualified file name (w/drive & path)

'Copyright (c) 1989 Ethan Winer


DEFINT A-Z
DECLARE FUNCTION FullName$ (PartName$)
DECLARE FUNCTION WhichError% ()

PRINT : PRINT : PRINT
PartName$ = "..\QB.EXE"
PRINT CHR$(34); PartName$; CHR$(34); "  ==>  ";
PRINT CHR$(34); FullName$(PartName$); CHR$(34);
IF WhichError% THEN PRINT "Error:"; WhichError%

