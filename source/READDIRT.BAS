'********** ReadDirT.Bas - reads a list of directories into a string array

'Copyright (c) 1987 Ethan Winer


DEFINT A-Z

DECLARE FUNCTION DCount (DSpec$)
DECLARE FUNCTION FCount (FSpec$)
DECLARE SUB ReadDirT (FSpec$, BYVAL Segment, BYVAL Address)

'we SHOULD be using "SEG Element" instead of "BYVAL Segment, BYVAL Address",
'but a "design decision" in QB 4 prevents this from working - the only way
'around the problem is to use a TYPE comprised solely of a fixed-length string

CLS

LINE INPUT "Enter a DIRECTORY name specification: "; DSpec$
PRINT

Count = DCount(DSpec$)                  'get the number of matching files
DIM DirName(Count) AS STRING * 12       'allocate enough strings for names

ReadDirT DSpec$, VARSEG(DirName$(0)), VARPTR(DirName$(0))

FOR X = 0 TO Count
    PRINT DirName$(X),
    IF Count < 19 THEN PRINT    'simulate "DIR /W" if more than 19 files
NEXT

PRINT
PRINT
PRINT Count; "Directories Found"

