'******* HCopy.Bas - demonstrates copying video pages on a Hercules display

'Copyright (c) 1988 Crescent Software


'NOTICE: This routine is intended for use on a Hercules display only.

DEFINT A-Z
DECLARE FUNCTION Monitor% ()

CLS
IF Monitor% <> 2 THEN
   PRINT "A Hercules display is required for this demonstration"
   END
END IF

FOR X = 1 TO 7          'fill screens 1 to 7 with strings of "1" through "7"
   PRINT STRING$(2000, CHR$(48 + X));   'print this on page zero
   CALL HCopy(0, X)                     'copy page zero to page X
NEXT X

FOR X = 7 TO 1 STEP -1          'retrieve the screens one by one
   CALL HCopy(X, 0)             'copy page X to page zero
   CALL WaitKey                 'wait for a key press
NEXT X

