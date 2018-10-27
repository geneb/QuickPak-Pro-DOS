'********** ScanFile.Bas

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z
DECLARE SUB FClose (Handle)
DECLARE SUB FGet (Handle, Destination$)
DECLARE SUB FOpen (FileName$, Handle)
DECLARE SUB FSeek (Handle, Location&)
DECLARE FUNCTION DOSError% ()
DECLARE FUNCTION WhichError% ()
DECLARE FUNCTION FLof& (Handle)
DECLARE FUNCTION QInstr% (Start, Source$, Search$)
DECLARE FUNCTION QInstr2% (Start, Source$, Search$)
DECLARE FUNCTION ScanFile& (FileName$, Text$, Start&)

'The offset returned by ScanFile is based at one.  That is, if a match is
'found at the very first byte in the file, Offset& returns 1, not 0.

FUNCTION ScanFile& (FileName$, Text$, Start&) STATIC

   ScanFile& = -1                       'assume an error
   L = 0                                'ditto

   FOpen FileName$, Handle              'open the file for QuickPak Binary
   IF DOSError THEN EXIT FUNCTION       'something bad must have happened
   Length& = FLof(Handle)               'now get the file's length
   IF Length& < 1 GOTO ExitFunction     'can't search a zero-length file
   IF Length& < LEN(Text$) GOTO ExitFunction    'text is longer than the file
                                                'so it can't possibly be there
   BufSiz& = 4096                               '4096 evenly holds 8 sectors
   IF BufSiz& > Length& THEN BufSiz& = Length&  'don't need more than Length&
   Temp$ = SPACE$(BufSiz&)                      'buffer for portions of file

   IF Start& < 1 THEN Start& = 1                'trap illegal start values
   IF Start& > Length& GOTO ExitFunction        'can't start past the end!

   LastSeek& = Start& - 1               'start searching where they asked
   BaseAddr& = LastSeek&
   Bytes = 0

   DO
       BaseAddr& = BaseAddr& + Bytes    'track the start of each block

       IF Length& - LastSeek& >= BufSiz& THEN
          Bytes = BufSiz&               'at least BufSiz& bytes still to do
       ELSE
          Bytes = Length& - LastSeek&   'get just what remains
          Temp$ = SPACE$(Bytes)         'FGet below uses LEN(Temp$) to know
       END IF                           '  how many bytes are to be read

       FSeek Handle, LastSeek&          'seek to that part of the file
       FGet Handle, Temp$               'read in a portion

       L = QInstr2%(1, Temp$, Text$)    'search this portion of the file
      'L = QInstr%(1, Temp$, Text$)     'or use this to honor capitalization

       IF L THEN EXIT DO                'we found it!

       IF LastSeek& + BufSiz& < Length& THEN 'still more to examine
          BaseAddr& = BaseAddr& - LEN(Text$) 'back up to avoid missing Text$
                                             ' in case it straddles a boundary
          LastSeek& = BaseAddr& + Bytes      'update the seek pointer
       ELSE
          EXIT DO                       'no more to read, exit loop
       END IF

   LOOP                                 'go examine some more

ExitFunction:
   FClose Handle                        'close the file

   IF L THEN
      ScanFile& = BaseAddr& + L         'assign the function output
   ELSE
      ScanFile& = 0                     'no match was found
   END IF

   Temp$ = ""                           'free up the memory

END FUNCTION

