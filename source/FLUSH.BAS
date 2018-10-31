'******* Flush.Bas - demonstrates flushing a file's buffers without closing it

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z
DECLARE FUNCTION Exist% (FileName$)
DECLARE FUNCTION FileSize& (FileName$)
DECLARE FUNCTION DOSError% ()
DECLARE FUNCTION WhichError% ()
DECLARE FUNCTION ErrorMsg$ (ErrNum)

DECLARE SUB FClose (Handle)
DECLARE SUB FCreate (FileName$)
DECLARE SUB FFlush (Handle)
DECLARE SUB FOpen (FileName$, Handle)
DECLARE SUB FPut (Handle, Text$)

CLS
FileName$ = "Flush.Tst"                     'the name of our test file
IF Exist%(FileName$) THEN KILL FileName$    'kill any old file if present

FCreate FileName$                           'create a new file
IF DOSError% THEN
   PRINT WhichError; ErrorMsg$(WhichError%)
   END
END IF
FOpen FileName$, Handle                     'now open it for Binary
FPut Handle, "This is a test."              'write something to it

PRINT "After writing to the file, but before flushing it the file's size is: ";
PRINT FileSize&(FileName$)                  'show that the file is now 0 bytes
PRINT "Press a key to continue"
CALL WaitKey                                'pause for a key press

FFlush Handle                               'flush the file buffers
PRINT "After flushing the file its size is: ";
PRINT FileSize&(FileName$)                  'now see how big the file is
FClose Handle                               'close it officially

