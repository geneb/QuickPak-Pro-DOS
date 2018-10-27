'********* ReadFile.Bas - demos reading a list of file names and sorting them

'Copyright (c) 1989 Ethan Winer


DEFINT A-Z
DECLARE SUB ReadFile (BYVAL Address)
DECLARE SUB SortStr (BYVAL Address, NumEls, Direction)
DECLARE FUNCTION FCount% (FileSpec$)

CLS
INPUT "Enter a file spec, or press Enter for *.* : ", Spec$
IF Spec$ = "" THEN Spec$ = "*.*"

NumFiles = FCount%(Spec$)               'see how many files there are
IF NumFiles = 0 THEN                    'none, end
   PRINT "No matching files found"
   END
END IF

DIM Array$(NumFiles)                    'make an array to hold the names
FOR X = 1 TO NumFiles                   'fill each element with 12 spaces
    Array$(X) = SPACE$(12)
NEXT
Array$(0) = Spec$                       'put the search spec into Array$(0)

ReadFile VARPTR(Array$(0))              'read the names into Array$()
SortStr VARPTR(Array$(1)), NumFiles, 0  'sort the array, 0 means "ascending"

FOR X = 1 TO NumFiles
    PRINT Array$(X)
NEXT

