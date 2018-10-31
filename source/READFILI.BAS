'********** READFILI.BAS - shows how ReadFileI returns full file information

'Copyright (c) 1989 Ethan Winer


DEFINT A-Z
DECLARE FUNCTION FCount% (FSpec$)
DECLARE FUNCTION WhichError%
DECLARE SUB ReadFileI (BYVAL Address)
DECLARE SUB WaitKey ()

CLS
LINE INPUT "Enter a file specification: ", FSpec$
Count = FCount%(FSpec$)         'see how many files match
IF Count = 0 THEN               'none, end now
  PRINT "No matching files"
  END
END IF

REDIM Array$(0 TO Count)        'make an array to hold the file names
Array$(0) = FSpec$              'put the search spec in the lowest element
FOR X = 1 TO Count              'assign each element to 37 spaces
    Array$(X) = SPACE$(37)      '  this step is mandatory to avoid trashing
NEXT                            '  string memory

CALL ReadFileI(VARPTR(Array$(0)))    'ReadFileI gets all the info in one shot

FOR X = 1 TO Count                   'print 'em to show it worked
    PRINT Array$(X)
    IF LEN(INKEY$) THEN CALL WaitKey 'pause on any key press
NEXT

PRINT Count; "file(s) reported"

