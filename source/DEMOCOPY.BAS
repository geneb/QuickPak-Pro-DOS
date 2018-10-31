'******** DEMOCOPY.BAS - demonstrates FileCopy.Bas

'Copyright (c) 1989 Ethan Winer


DEFINT A-Z
DECLARE SUB FileCopy (Source$, Dest$, Copied, ErrFlag)
DECLARE FUNCTION DOSError% ()
DECLARE FUNCTION WhichError% ()

CLS
LINE INPUT "Enter a source file or spec (ie: *.BAS) : ", Source$
LINE INPUT "Enter a destination drive letter or path: ", Dest$
PRINT
CALL FileCopy(Source$, Dest$, Copied, ErrCode)

IF DOSError% THEN
   PRINT "Error"; WhichError; "occurred on the ";
   IF ErrCode = 1 THEN
      PRINT "source";
   ELSE
      PRINT "destination";
   END IF
   PRINT " drive or path."
END IF

PRINT Copied; " files copied."

