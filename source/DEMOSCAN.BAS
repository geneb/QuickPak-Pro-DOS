'********** DemoScan.Bas - demos the BASIC ScanFile function

'This example shows how to use the QuickPak Pro Binary file routines to
'search a file for any string or substring.

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z
DECLARE FUNCTION DOSError% ()
DECLARE FUNCTION WhichError% ()
DECLARE FUNCTION ErrorMsg$ (ErrNum)
DECLARE FUNCTION ScanFile& (FileName$, SearchText$, Start&)

'The offset returned by ScanFile is based at one.  That is, if a match is
'found at the very first byte in the file, Offset& returns 1, not 0.


CLS
LINE INPUT "Program to search: ", FileName$
LINE INPUT "     Text to find: ", SearchText$

Offset& = 0                 'start searching at the beginning of the file

DO
    Start& = Offset& + 1    'this allows continuing the search

    Offset& = ScanFile&(FileName$, SearchText$, Start&)  'search the file
    IF DOSError% THEN
       PRINT "Error"; WhichError%; "occurred - "; ErrorMsg$(WhichError%)
       END
    END IF

    PRINT

    IF Offset& < 1 THEN         'ScanFile& returns 0 for "not found", and -1
       PRINT "Text not found"   '  if you start past the end of the file or
       END                      '  the search string is longer than the file.
    ELSE
       PRINT "Found at"; Offset&     'anything else is where the text was found
    END IF

    PRINT "Keep searching (Y/N)? ";
    DO
       X$ = UCASE$(INKEY$)
    LOOP UNTIL LEN(X$)

LOOP WHILE X$ = "Y"

