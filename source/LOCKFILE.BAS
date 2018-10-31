'********** LockFile.Bas - locks files behind BASIC's back

'Copyright (c) 1987 Ethan Winer


'This program demos the LockFile and UnLockFile assembler routines which
'lock and unlock files directly through DOS.  This avoids the possibility
'of generating a BASIC error which would require ON ERROR to trap.

'If the file is successfully locked, it is not necessary to do it again
'in BASIC.  This will be indicated by the DOSError% and WhichError% functions
'returning 0.  If DOS does not allow the locking to take place, WhichError%
'will be set to either 73 or 85.  An error code of 73 means that SHARE.EXE
'has not been installed, and 85 means the file is already locked.

'To run this demo, you must provide the name of the network file to lock,
'the record number to be locked, and the length of each record.  LockTest
'will then attempt to lock the file, and report whether it was successful.

'We have also provided a routine to unlock files, but it probably is not
'necessary because BASIC's UNLOCK will work just as well.  However, the
'UnLockFile routine will also report errors without messing up BASIC.


DEFINT A-Z

DECLARE SUB LockFile (DOSHandle, Offset&, Length&)
DECLARE SUB UnLockFile (DOSHandle, Offset&, Length&)
DECLARE SUB WaitKey ()
DECLARE FUNCTION DOSError% ()
DECLARE FUNCTION WhichError% ()


CLS
INPUT " Name of file to lock: ", FileName$
INPUT "Record number to lock: ", Record
INPUT "Length of each record: ", Length&
INPUT "    Number of records: ", NumRecs

OPEN FileName$ FOR RANDOM SHARED AS #1 LEN = Length&

DOSHandle = FILEATTR(1, 2)                      'get the DOS file handle
Offset& = (Record - 1) * Length&                'calculate start offset
LockLength& = Length& * NumRecs                 'calculate the number of bytes
LockFile DOSHandle, Offset&, LockLength&        'try to lock it

IF DOSError% THEN
   PRINT "The lock attempt failed with error"; WhichError%
ELSE
   PRINT "Locking successful"
   PRINT
   PRINT "Press a key when ready to unlock the file: ";
   WaitKey
   UnLockFile DOSHandle, Offset&, LockLength&   'we must unlock it again!
   IF DOSError THEN                             'unlikely to have an error now
      PRINT "But now I can't unlock the file again, error"; WhichError%
   END IF
END IF

CLOSE #1

