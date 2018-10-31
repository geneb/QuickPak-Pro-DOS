'********** ReadFilX - shows how to use ReadFileX to get full file information

'Copyright (c) 1989 Ethan Winer


DEFINT A-Z
DECLARE FUNCTION DOSError% ()
DECLARE FUNCTION FCount% (FSpec$)
DECLARE SUB ReadFileX (FSpec$, DirSize&, SEG Element AS ANY)
DECLARE SUB WaitKey ()

TYPE FullInfo
    BaseName AS STRING * 8
    ExtName  AS STRING * 3
    FileSize AS LONG
    FileDate AS STRING * 8
    FileTime AS STRING * 6
    Attrib   AS STRING * 1
END TYPE

CLS
LINE INPUT "Enter a file specification: ", FSpec$
IF FSpec$ = "" THEN FSpec$ = "*.*"   'default to all files 
Count = FCount%(FSpec$)              'see how many files match
IF Count = 0 THEN END                'none, end now

REDIM Array(1 TO Count) AS FullInfo  'make an array to hold the full file info
ReadFileX FSpec$, DirSize&, Array(1) 'ReadFileX gets all the info in one shot

FOR X = 1 TO Count                   'print 'em to show it worked
    PRINT RTRIM$(Array(X).BaseName);
    IF LEN(RTRIM$(Array(X).ExtName)) THEN PRINT ".";
    PRINT Array(X).ExtName; TAB(13);
    PRINT USING "##########"; Array(X).FileSize;
    PRINT TAB(26);
    PRINT Array(X).FileDate; TAB(37);
    PRINT Array(X).FileTime; TAB(46);

    Attribute = ASC(Array(X).Attrib) 'isolate the attribute byte
    IF Attribute AND 1 THEN PRINT "read-only  ";
    IF Attribute AND 2 THEN PRINT "hidden  ";
    IF Attribute AND 4 THEN PRINT "system";
    PRINT
    IF LEN(INKEY$) THEN WaitKey      'pause on any key press
NEXT

PRINT
PRINT Count; "file(s) reported,"; DirSize&; "total bytes occupied"

