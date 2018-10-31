'******** DemoFC.Bas - demonstrates encrypting a file with a password

'Copyright (c) 1988 Ethan Winer

'IMPORTANT: do NOT forget your password!


DEFINT A-Z
DECLARE SUB FileCrypt (FileName$, PassWord$)
DECLARE FUNCTION DOSError% ()
DECLARE FUNCTION WhichError% ()


CLS
LINE INPUT "File to encrypt/decrypt: ", F$
LINE INPUT "               Password: ", P$

FileCrypt F$, P$
IF DOSError% THEN
   SELECT CASE WhichError%
      CASE 53
         PRINT "File not found."
      CASE 71
         PRINT "Drive not ready."
      CASE 75
         PRINT "File is read-only."
      CASE ELSE
         PRINT "Error"; WhichError%
   END SELECT
ELSE
   PRINT F$; " successfully encrypted"
END IF

