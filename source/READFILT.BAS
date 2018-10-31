'********* ReadFilT.Bas - reads a list of file names into a fixed-length array

'Copyright (c) 1989 Ethan Winer


DEFINT A-Z
DECLARE SUB ReadFileT (Spec$, SEG Element AS ANY)
DECLARE SUB SortT (SEG Element AS ANY, NumEls, Direction, TotalSize, Offset, StrSize)
DECLARE FUNCTION FCount% (FileSpec$)

TYPE FLen                               'using a TYPE greatly simplifies the
   S AS STRING * 12                     '  call to ReadFileT
END TYPE

CLS
INPUT "Enter a file spec, or press Enter for *.* : ", Spec$
IF Spec$ = "" THEN Spec$ = "*.*"

NumFiles = FCount%(Spec$)               'see how many files there are
IF NumFiles = 0 THEN
   PRINT "No matching files found"
   END
END IF

DIM Array(1 TO NumFiles) AS FLen        'make an array to hold the names

ReadFileT Spec$, Array(1)               'read the names into Array
SortT Array(1), NumFiles, 0, 12, 0, 12  'sort the array, 0 means ascending

FOR X = 1 TO NumFiles
    PRINT Array(X).S
NEXT

