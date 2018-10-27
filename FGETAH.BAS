'********** FGetAH.Bas - demos FGetAH and FPutAH

'Copyright (c) 1989 Ethan Winer


'You must start QuickBASIC with the /AH switch to run this demo
'(You'll also need 192,000 bytes of extra far memory)


DEFINT A-Z
DECLARE SUB FGetAH (FileName$, SEG Address AS ANY, ElSize, NumEls)
DECLARE SUB FPutAH (FileName$, SEG Address AS ANY, ElSize, NumEls)
DECLARE SUB WaitKey ()

ElSize = 8
NumEls = 24000                  'make this smaller if you run out of memory

CLS
PRINT "Creating test array with"; NumEls; "elements ..."
REDIM Array#(1 TO NumEls)               'make a huge array
FOR X = 1 TO NumEls                     'file it with inceasing values
    Array#(X) = X
NEXT

PRINT "Writing the array to disk ..."
FPutAH "AHTest", Array#(1), ElSize, NumEls   'write it to disk
REDIM Array#(1 TO NumEls)                    'erase the array and start over
PRINT "Loading the array from disk ..."
FGetAH "AHTest", Array#(1), ElSize, NumEls   'read it back from disk

PRINT "Testing for errors ..."
FOR X = 1 TO NumEls                     'test that the file loaded okay
    IF Array#(X) <> X THEN
       BEEP
       PRINT "Error in element"; X
       WaitKey
    END IF
NEXT

KILL "AHTest"

