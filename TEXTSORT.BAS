'******** TEXTSORT.BAS - file sort for ASCII text files

'Copyright (c) 1994 Ethan Winer


'NOTE: Some LOCATE and PRINT statements are in the TextSort subprogram to
'      show the progress.  They are useful if you are using DEMOTSRT.BAS as
'      a stand-alone utility, but you can remove them if you add TextSort to
'      your own programs.  There's also a modification you may find useful to
'      make: After the Index&() and Length() arrays have been built you could
'      save them to disk (use FPutAH) to access the file in sorted order, and
'      then REM out the code that writes the output file.

DEFINT A-Z
DECLARE FUNCTION FileSize& (FileName$)
DECLARE FUNCTION ReadLine$ (Offset&, Length%)
DECLARE FUNCTION TextSort% (InFile$, OutFile$)
DECLARE FUNCTION WhichError% ()

DECLARE SUB FCreate (FileName$)
DECLARE SUB FGet (Handle, Work$)
DECLARE SUB FOpen (FileName$, Handle)
DECLARE SUB FSeek (Handle, Offset&)

DIM SHARED InHandle                     'shared between TextSort and ReadLine

FUNCTION ReadLine$ (Offset&, Length) STATIC
 
  'reads a line of text from the input file
  Text$ = SPACE$(Length)                'create space to receive the line
  CALL FSeek(InHandle, Offset&)         'seek to that place in the file
  CALL FGet(InHandle, Text$)            'read the string
  ReadLine$ = Text$                     'return it as the function output

END FUNCTION

FUNCTION TextSort% (InFile$, OutFile$) STATIC

  'The Index&() and Length() arrays hold the starting offset for each line in
  'the file and each line's length.  The MaxLines constant limits how large a
  'file this routine can sort.  You can make the arrays larger to accommodate
  'larger files, but you will then have to compile this module using the /Ah
  'switch and also start the BASIC editor with /Ah.
  '
  CONST MaxLines% = 16384
  REDIM Index&(1 TO MaxLines%)
  REDIM Length(1 TO MaxLines%)
  REDIM TStack(1 TO MaxLines% \ 3)

  CR$ = CHR$(13)                'invoke CHR$() just once for speed
  CRLF$ = CR$ + CHR$(10)
 
  NumLines = 1                  'number of lines in the file (1-based)
  Offset& = 0                   'this tracks the starting offset of each line

  InSize& = FileSize&(InFile$)          'see how big the file is
  IF InSize& <= 0 GOTO ErrorExit        'zero-length file or no such file

  'Open the file to count the number of lines, and build an index to where in
  'the file each line begins (indexes are zero-based) and save each length.
  '
  PRINT "Indexing the input file...";
  CALL FOpen(InFile$, InHandle)         'try to open the file
  IF WhichError% GOTO ErrorExit         'there was an error, return it
 
  BytesLeft& = InSize&                  'tracks how much of the file was read
  NumBytes = 4096                       'assume we'll read a 4k block
  Buffer$ = SPACE$(NumBytes)            'read it into this buffer

  'Read a buffer-full of text and count the CHR$(13) bytes.  After the last
  'CHR$(13) is found seek back to the start of the current line, and continue
  'until the entire file has been processed.
  '
  DO

    IF BytesLeft& < 4096 THEN           'less than 4k left
      NumBytes = BytesLeft&             'read only what remains
      Buffer$ = SPACE$(NumBytes)
    END IF

    CALL FGet(InHandle, Buffer$)        'read a chunk of the file
    BytesLeft& = BytesLeft& - NumBytes  'show we read this much
    Start = 1                           'tracks the CHR$(13)'s in the buffer

    DO

      Found = INSTR(Start, Buffer$, CR$)'look for the CHR$(13)
      CurLength = Found - Start         'calculate this line's length

      IF Found THEN                     'we found one
        Index&(NumLines) = Offset&      'assign this line's file offset
        Length(NumLines) = CurLength    'and its length
        Start = Start + CurLength + 2   'skip this line, the CR, and the LF
        Offset& = Offset& + CurLength + 2
        NumLines = NumLines + 1         'show there's one more line
        IF NumLines > MaxLines% THEN    'the input file is too big!
          TextSort% = 100               '100 is the closest "standard" error
          GOTO ExitSort                 '  we have in QuickPak
        END IF
      ELSE
        IF BytesLeft& = 0 THEN EXIT DO  'it's the last line but there's no CR
        BytesLeft& = BytesLeft& + (NumBytes - Start) + 1
        CALL FSeek(InHandle, Offset&)   'seek back to the start of this line
        IF WhichError% GOTO ErrorExit   'there was an error, return it
      END IF

    LOOP WHILE Found                    'while there are CRs in the buffer
 
  LOOP WHILE BytesLeft&                 'while there's more file to be read

  NumLines = NumLines - 1               'because we added one too many above
  PRINT NumLines; "lines processed."
  PRINT "Sorting";
 
  'QuickSort the file by first sorting the index, and then writing the lines
  'in order from the input file to the output file.  If we got this far with
  'no DOS errors, there won't be any further errors from merely seeking and
  'reading the input file.  So don't slow down ReadLine with a bunch of calls
  'to the WhichError%() function.
  '
  S = 1                                 'initialize work variables
  F = 1
  L = NumLines

L1:
  Progress = Progress + 1               'delete these along with the PRINTs
  LOCATE , 9                            'print every fourth time through
  PRINT MID$("|/-\", (Progress MOD 4) + 1, 1);
  
  I = F
  J = L
  MidPoint = (L + F) \ 2                'calc. midpoint and read that string
  MidPoint$ = ReadLine$(Index&(MidPoint), Length(MidPoint))

L2:
  WHILE ReadLine$(Index&(I), Length(I)) < MidPoint$ 'use > for descending
    I = I + 1
  WEND

  WHILE ReadLine$(Index&(J), Length(J)) > MidPoint$ 'use < for descending
    J = J - 1
  WEND
 
  IF I > J GOTO L3
  IF I < J THEN
    SWAP Index&(I), Index&(J)
    SWAP Length(I), Length(J)
  END IF

  I = I + 1
  J = J - 1
  IF I <= J GOTO L2

L3:
  IF I < L THEN
    TStack(S) = I                        'Push I, L
    TStack(S + 1) = L
    S = S + 2
  END IF

  L = J
  IF F < L GOTO L1
  IF S = 1 GOTO WriteFile               'all done sorting
 
  S = S - 2                             'Pop L, F
  F = TStack(S)
  L = TStack(S + 1)
  GOTO L1

WriteFile:
  'Read the input file in order of the now-sorted index, and write the lines
  'to the output file adding a CRLF to each line as required by FPut.
  '
  LOCATE , 9: PRINT "Done."
  PRINT "Creating the output file."

  CALL FCreate(OutFile$)
  IF WhichError% GOTO ErrorExit         'make sure the output file is created
  CALL FOpen(OutFile$, OutHandle)
 
  FOR X = 1 TO NumLines
    Temp$ = ReadLine$(Index&(X), Length(X))
    CALL FPut(OutHandle, Temp$ + CRLF$)
  NEXT

ErrorExit:
  TextSort% = WhichError%               'if an error occurred, return it
                                        '(no errors will simply return zero)
ExitSort:
  CALL FClose(InHandle)
  CALL FClose(OutHandle)
  ERASE Index&, Length, TStack

END FUNCTION

