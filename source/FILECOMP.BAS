'********* FILECOMP.BAS - compares two files

'Copyright (c) 1989 Ethan Winer


DEFINT A-Z
DECLARE SUB FClose (Handle)
DECLARE SUB FGetA (Handle, SEG Element AS ANY, NumBytes)
DECLARE SUB FOpen (FileName$, Handle)
DECLARE SUB SetError (ErrNum)

DECLARE FUNCTION CompareT% (SEG Type1 AS ANY, SEG Type2 AS ANY, NumBytes)
DECLARE FUNCTION DOSError% ()
DECLARE FUNCTION FileComp% (File1$, File2$, ErrCode)
DECLARE FUNCTION FLof& (Handle)
DECLARE FUNCTION WhichError% ()

TYPE FComp
   Info AS STRING * 4096
END TYPE

FUNCTION FileComp% (File1$, File2$, ErrCode)

    ErrCode = 0                         'assume no errors for now
    CALL FOpen(File1$, Handle1)         'open the first file
    IF DOSError THEN                    'if there was an error ...
       ErrCode = 1                      'show that it happened on file one
       EXIT FUNCTION                    'and exit
    END IF

    CALL FOpen(File2$, Handle2)         'open the second file
    IF DOSError% THEN                   'if there was an error ...
       ErrCode = 2                      'show that it happened on file two
       OldError = WhichError%           'remember the error that just happened
       CALL FClose(Handle1)             'close the first file that's now open
       CALL SetError(OldError)          'a successful FClose cancels DOSError,
       EXIT FUNCTION                    '  so set it again, and get out
    END IF

    FileSiz& = FLof&(Handle1)           'see how big the first file is
    IF FileSiz& = FLof&(Handle2) THEN   'they're the same size, continue
       FileComp% = -1                   'assume they're the same
       BytesLeft& = FileSiz&            'track how many bytes remain
       REDIM Array(1 TO 2) AS FComp     'make a far array to hold the files

       DO                               'this is the main compare loop
          IF BytesLeft& <= 4096 THEN    'if there's less than 4096 bytes left
             BlockSize = BytesLeft&     'read only what remains
          ELSE
             BlockSize = 4096           'otherwise, read a full 4096 bytes
          END IF

          CALL FGetA(Handle1, Array(1), BlockSize)  'get from the first file
          IF DOSError% THEN                     'an error occurred
             ErrCode = 1                        'on the first file
             EXIT DO                            'get out
          END IF
         
          CALL FGetA(Handle2, Array(2), BlockSize)  'get from the second file
          IF DOSError% THEN                     'an error occurred
             ErrCode = 2                        'on the second file
             EXIT DO                            'get out
          END IF

          BytesLeft& = BytesLeft& - BlockSize   'show we did this many bytes

          IF NOT CompareT%(Array(1), Array(2), BlockSize) THEN   'not the same
             FileComp% = 0      'show that the compare failed
             EXIT DO            'and exit the loop
          END IF

       LOOP WHILE BytesLeft&    'loop until the files have been fully examined
       ERASE Array              'free up the memory
    ELSE                        'the files are different sizes, so
       FileComp% = 0            'show that the compare failed
    END IF

    CALL FClose(Handle1)        'close both files
    CALL FClose(Handle2)

END FUNCTION

