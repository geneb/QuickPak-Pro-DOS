'********** GetAttr.Bas - gets a file's attributes

'Copyright (c) 1987 Ethan Winer


DEFINT A-Z
DECLARE FUNCTION GetAttr% (FileName$)

CLS
LINE INPUT "File Spec: "; F$

Attr = GetAttr%(F$)             'get the attribute

PRINT
IF Attr = -1 THEN
   PRINT "Sorry, that file doesn't exist."
ELSE
   PRINT "Attribute = ";
   IF Attr = 0 THEN PRINT "None"
   IF Attr AND 1 THEN PRINT "Read-Only ";
   IF Attr AND 2 THEN PRINT "Hidden ";
   IF Attr AND 4 THEN PRINT "System ";
   IF Attr AND 16 THEN PRINT "Subdirectory ";
   IF Attr AND 32 THEN PRINT "Archive";
END IF

