DEFINT A-Z
DECLARE SUB Handle2Name (BYVAL Handle, FileName AS ANY)

TYPE NameType
  FileName  AS STRING * 8
  Extension AS STRING * 3
END TYPE

DIM FilName AS NameType
OPEN "\dev\nul" FOR RANDOM AS #1
OPEN "TEST.DAT" FOR OUTPUT AS #2
OPEN "hand2nam.bas" FOR INPUT AS #3

PRINT "Handle FileName Ext"
PRINT "==================="

FOR Handle = 0 TO 19
  CALL Handle2Name(Handle, FilName)
  PRINT TAB(3); Handle;
  PRINT TAB(8); FilName.FileName; " "; FilName.Extension
NEXT

CLOSE

