'********** FileInfo.Bas - retrieves information about a file or directory

'Copyright (c) 1987 Ethan Winer


DEFINT A-Z
DECLARE FUNCTION DOSError% ()                   'to trap possible DOS errors
DEF FnP$ (X) = RIGHT$("0" + LTRIM$(STR$(X)), 2) 'adds a leading zero if needed

'The syntax example given in the owner's manual uses an array to receive
'the information that FileInfo returns.  However, we believe that using a
'TYPE variable as shown below is much simpler, and will make your programs
'easier to read and maintain.  As it works out, FileInfo works just as well
'using either method, so use whichever you prefer.


TYPE FInfo
   Year   AS INTEGER
   Month  AS INTEGER
   Day    AS INTEGER
   Hour   AS INTEGER
   Minute AS INTEGER
   Second AS INTEGER
   Size   AS LONG
   Attrib AS INTEGER
END TYPE
DIM Info AS FInfo               'Info will receive the returned information

CLS
LINE INPUT "File Name to get info about: "; FileName$
CALL FileInfo(FileName$, SEG Info)

IF DOSError% THEN
   PRINT "File "; FileName$; " was not found."
   END
END IF

PRINT
PRINT "Date      = ";
PRINT FnP$(Info.Month); "/"; FnP$(Info.Day); "/"; FnP$(Info.Year)

PRINT "Time      = ";
PRINT FnP$(Info.Hour); ":"; FnP$(Info.Minute); ":"; FnP$(Info.Second)

PRINT "File Size ="; Info.Size

PRINT "Attribute = ";
   IF Info.Attrib AND 1 THEN PRINT "Read-Only ";
   IF Info.Attrib AND 2 THEN PRINT "Hidden ";
   IF Info.Attrib AND 4 THEN PRINT "System ";
   IF Info.Attrib AND 16 THEN PRINT "Subdirectory ";
   IF Info.Attrib AND 32 THEN PRINT "Archive";

