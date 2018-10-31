'********** DEMOCOMP.BAS - shows FileComp in action

'Copyright (c) 1989 Ethan Winer


DEFINT A-Z
DECLARE FUNCTION FileComp% (File1$, File2$, ErrCode)

DECLARE FUNCTION DOSError% ()
DECLARE FUNCTION WhichError% ()
DECLARE FUNCTION ErrorMsg$ (ErrNum)

CLS
LINE INPUT "Enter the name of the  first file: ", File1$
LINE INPUT "Enter the name of the second file: ", File2$
PRINT

IF FileComp%(File1$, File2$, ErrCode) THEN
   PRINT "The files are the same"
   END
END IF

IF DOSError% THEN                       'a DOS error occurred
   PRINT ErrorMsg$(WhichError%);        'print an appropriate message
   PRINT " error reading file ";
   IF ErrCode = 1 THEN                  'and show if the error was
      PRINT File1$                      'on the first file
   ELSE
      PRINT File2$                      'or the second file
   END IF
ELSE                                    'no error, they're just different
   PRINT "The files are different";
END IF

