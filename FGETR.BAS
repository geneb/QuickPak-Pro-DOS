'*********** FGetR.Bas - demonstrates FGetR and FPutR in context

'Copyright (c) 1989 Ethan Winer


DEFINT A-Z
DECLARE SUB FClose (Handle)
DECLARE SUB FCreate (FileName$)
DECLARE SUB FGetR (Handle, Destination$, RecNumber&)
DECLARE SUB FOpen (FileName$, Handle)
DECLARE SUB FPutR (Handle, Source$, RecNumber&)
DECLARE SUB KillFile (FileName$)

DECLARE FUNCTION DOSError% ()
DECLARE FUNCTION WhichError% ()
DECLARE FUNCTION ErrorMsg$ (ErrNumber)

CLS
F$ = "Random.Tst"               'this will be our test file
Source$ = SPACE$(40)            'this sets the record length

FCreate F$                      'create the file
IF DOSError% THEN               'see if an error occurred creating the file
   PRINT ErrorMsg$(WhichError%)
   END
END IF

FOpen F$, Handle                        'open for QuickPak Professional Binary

FOR Record& = 1 TO 100                  'create one hundred records
    LSET Source$ = "Testing" + STR$(Record&)
    FPutR Handle, Source$, Record&
    IF DOSError% THEN                   'check for possible full disk
       PRINT ErrorMsg$(WhichError%)
       END
    END IF
NEXT

FOR Record& = 99 TO 1 STEP -10  'read records backwards to prove it all works
    FGetR Handle, Source$, Record&
    PRINT "Record"; Record&, Source$
NEXT

FClose Handle                   'close the file
KillFile F$                     'why clutter up the disk with this nonsense?

