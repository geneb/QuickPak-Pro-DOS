'********** Exist.Bas - demonstrates the file and directory exist functions

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z
DECLARE FUNCTION Exist (FSpec$)
DECLARE FUNCTION DOSError% ()
DECLARE FUNCTION WhichError% ()

CLS
INPUT "Enter a file spec: ", FSpec$
IF Exist(FSpec$) THEN
   PRINT "It's there!"
ELSE
   PRINT "Not found"
   IF DOSError% THEN
      BEEP
      PRINT "Error"; WhichError%; "Occurred."
   END IF
END IF

