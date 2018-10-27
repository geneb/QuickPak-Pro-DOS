'*********** FILESORT.BAS - sorts an index to the file on any number of keys

'Copyright (c) 1989 Crescent Software
'Written by Paul Passarelli
' 01/12/93 .001 Add explicit lower bound to arrays in Sub FileSort

DEFINT A-Z

DECLARE SUB BCopy (FromSeg, FromAdr, TOSeg, TOAdr, NumBytes, Direction)
DECLARE SUB FClose (Handle)
DECLARE SUB FCreate (FileName$)
DECLARE SUB FOpen (FileName$, Handle)
DECLARE SUB FGet (Handle, Dest$)
DECLARE SUB FGetR (Handle, Dest$, RecNo&)
DECLARE SUB FGetT (Handle, Source AS ANY, NumBytes)
DECLARE SUB FPutAH (FileName$, SEG Element AS ANY, ElSize, NumEls)
DECLARE SUB FPutT (Handle, Source AS ANY, NumBytes)
DECLARE SUB FSeek (Handle, Location&)
DECLARE SUB KeySort (SEG ArrayElement AS ANY, ElSize, NumEls, SEG TableElement, NumKeys)
DECLARE SUB KillFile (FileName$)
DECLARE SUB SegAdr (Segment, Address)
DECLARE SUB SetError (ErrCode)


DECLARE FUNCTION AddUSI% (A, B)
DECLARE FUNCTION DOSError% ()
DECLARE FUNCTION DOSVer% ()
DECLARE FUNCTION ErrorMsg$ (ErrCode)
DECLARE FUNCTION Exist% (FileName$)
DECLARE FUNCTION FileSize& (FileName$)
DECLARE FUNCTION FLof& (Handle)
DECLARE FUNCTION FreeHandles% ()        'BASIC Function in FileSort.BAS
DECLARE FUNCTION MaxInt% (A, B)
DECLARE FUNCTION MinInt% (A, B)
DECLARE FUNCTION QPSSeg% (Text$)
DECLARE FUNCTION WhichError% ()


TYPE PassFileData       'used in the merge sort
     Rno AS LONG        'the record number from the data file
     Fno AS INTEGER     'the temporary file where the record number is
END TYPE

'syntax example
'
'Call FileSort (DataFile$, IndexFile$, First&, Last&, Table(), RecLength)
'
'Note that First& and Last& may be zero to indicate the entire DataFile is
'to be sorted.  First& will return as 1, Last& will return as NumRecs.
'If RecLength is passed as a negative number, the program will do a case-
'insensitive sort.

SUB FileSort (DataFile$, IndexFile$, First&, Last&, Table(), RecLength)

    SetError Zero                       'clear any DOS errors

    IF RecLength < 0 THEN               'if the record length is negative
       NoCase = -1                      '  they want to sort ignoring
       RecLength = ABS(RecLength)       '  capitalization
    END IF

    IF FRE("") < RecLength THEN         'see to it that string space will
       SetError 7                       'hold at least one record!
    END IF
   
    IF FRE(-1) < 16384 THEN             'I won't even try with less memory
       SetError 7                       'rem it out if you choose, but, it may
    END IF                              'fail for other reasons

    IF RecLength <= Zero THEN           'this must be specified
       SetError 127                     'division by zero is undefined
    END IF
   
    IF RecLength > 16384 THEN           'are your records really that big?
       SetError 127                     'sorry you'll have to modify the code
    END IF
  
    IF First& > Last& THEN
       SetError 100                     'Insufficient number of elements
    END IF
   
    IF WhichError GOTO ErrExit1         'check for any simple errors
   
    IF NOT Exist(DataFile$) THEN        'be sure to find the datafile
       SetError 53                      'can't find it, let'em know
    END IF
   
    IF FileSize&(DataFile$) MOD RecLength THEN
       SetError 82                      'Invalid Parameter
    END IF
   
    IF WhichError GOTO ErrExit1         'check for any simple errors
   
    FCreate (IndexFile$)                'prepare the index here
    IF WhichError GOTO ErrExit1         'last check for simple error

    IF Last& = Zero THEN                'this assumes they want the default
       Last& = FileSize&(DataFile$) \ RecLength 'this should be passed back
       IF Last& = Zero THEN             'this can't be a default
          SetError 62                   'so, don't read more than there is
       ELSE                             'otherwise...
          First& = 1                    'this is the rest of the default
       END IF
    END IF
    IF WhichError GOTO ErrExit2         'ErrExit2 cleans up any tracks

    NumRecs& = Last& - First& + 1       'total no of records
    NumKeys = UBOUND(Table, 1)          'number of sort keys
   
    '----- Process the Table array to determine total KeyBytes & KeyOffsets
    '      for the Table3 array used by KeySort
    DIM Table2(1 TO NumKeys)            'hold evaluated codes as byte counts
    DIM Table3(1 TO NumKeys, 1 TO 3)    'compressed for KeySort.Asm
    FOR I = 1 TO NumKeys
        SELECT CASE Table(I, 2)         'size/code for fielded data
           CASE -1
              Table2(I) = 2             'Integer
           CASE -2
              Table2(I) = 4             'Long Integer
           CASE -3
              Table2(I) = 4             'Single
           CASE -4
              Table2(I) = 8             'Double
           CASE ELSE
              Table2(I) = Table(I, 2)   'Fixed Length String
        END SELECT
        Table3(I, 1) = KeyBytes         'the cumulative offset into
        Table3(I, 2) = Table(I, 2)      '   the Key Data being sorted
        Table3(I, 3) = Table(I, 3)
        KeyBytes = KeyBytes + Table2(I) 'keep a running total
    NEXT
   
    IF KeyBytes > RecLength THEN
       SetError 82                      'attempt to sort more than there is
    END IF

    SELECT CASE KeyBytes                'see how big a `block-o-memory'
       CASE IS <= 2                     'each record will occupy
          KeyElSize = 8                 'keeping it a power of two
       CASE IS <= 10
          KeyElSize = 16
       CASE IS <= 26
          KeyElSize = 32
       CASE IS <= 58
          KeyElSize = 64
       CASE IS <= 122
          KeyElSize = 128
       CASE IS <= 250
          KeyElSize = 256
       CASE IS <= 506
          KeyElSize = 512
       CASE IS <= 1018
          KeyElSize = 1024
       CASE IS <= 2042
          KeyElSize = 2048
       CASE IS <= 4090
          KeyElSize = 4096
       CASE IS <= 8186
          KeyElSize = 8192
       CASE IS <= 16378
          KeyElSize = 16384
       CASE ELSE
          SetError 127
    END SELECT

    IF KeyElSize > FRE("") THEN         'is there enough string space
       SetError 14                      'no,  tell'em
    END IF

    FarHeap& = FRE(-1) - 2112           'far memory adjusted down by a little
   
    IF FarHeap& < 2 * KeyElSize THEN    'will it hold 2 key block & index
       SetError 7                       'no,??!! not even close!
    END IF

    P = 1 + NumRecs& * KeyElSize \ FarHeap&
    DO WHILE FarHeap& < NumRecs& * KeyBytes \ P
       P = P + 1                        'unlikly but possible
    LOOP
    DO WHILE NumRecs& \ P > 32767
       P = P + 1                        'even more unlikly but possible
    LOOP
   
    IF WhichError GOTO ErrExit3         'even more stuff to clean up
    SetError Zero                       'give freehandles a fresh chance
    IF P >= FreeHandles - 2 THEN
       SetError 78
       GOTO ErrExit3
    END IF
   
    IF P = 1 THEN                       'how many phases
       EachTime = Zero
       LastTime = NumRecs&              'one pass fits all
    ELSE
       EachTime = NumRecs& \ P                    'most of-em
       LastTime = NumRecs& - (CLNG(EachTime) * P) 'all the rest
    END IF
   
    PassRecs = MaxInt(EachTime, LastTime)       'used here to allocate memory
                                                'used later for pass countdown
    IF KeyElSize > 8 THEN
       XX = KeyElSize \ 8               '8 byte columns for the Work# array
    ELSE
       XX = 1
    END IF
    REDIM Work#(1 TO XX, 1 TO PassRecs)
   
    '----- pre-assign ALL loop variables here!!
    Garbage& = FRE("")                  '  these variables are used in the
    DIM PFD AS PassFileData             '  data transfer loop.
    T& = Zero                           '
    T% = Zero                           '
    PassHi& = Zero
    PassLo& = Zero
    Ky = Zero
    DestSeg = Zero: LDAdr = Zero
    WorkSeg = Zero: WorkADR = Zero
    Dest$ = STRING$(RecLength, Zero)

    DestSeg = QPSSeg(Dest$)
    DestAdr = SADD(Dest$)
    WorkSeg = VARSEG(Work#(1, 1))
    WorkADR = VARPTR(Work#(1, 1))
   
    FOpen DataFile$, Handle
    IF DOSError GOTO ErrExit4
   
    PassLo& = First&                    'honor a partial sort
    PadBytes = KeyElSize - KeyBytes     'to round up to the power of 2

    IF First& > 1 THEN                  'EW 10-22-96 to handle starting > 1
      CALL FSeek(Handle, (First& - 1) * RecLength)
    END IF
   
    IF EachTime THEN                    'do we do regular multiple passes?
       FOR T = 1 TO P                   'yes, T for Temp loop counter
           PFD.Fno = T                         'assign it to the TYPE
           PassHi& = PassLo& - 1 + EachTime
           FOR T& = PassLo& TO PassHi&          'loop through rec.nos.
               PFD.Rno = T&                     'assign type
               FGet Handle, Dest$               'read the record
               FOR Ky = 1 TO NumKeys            'parse it
                   IF NoCase THEN
                      IF Table(Ky, 2) > 0 THEN
                         MID$(Dest$, Table(Ky, 1) + 1, Table2(Ky)) = UCASE$(MID$(Dest$, Table(Ky, 1) + 1, Table2(Ky)))
                      END IF
                   END IF
                   BCopy DestSeg, DestAdr + Table(Ky, 1), WorkSeg, WorkADR, Table2(Ky), Zero
                   WorkADR = AddUSI(WorkADR, Table2(Ky))
               NEXT
               BCopy VARSEG(PFD), VARPTR(PFD), WorkSeg, WorkADR, 6, Zero    'copy additional info
               WorkADR = AddUSI(WorkADR, PadBytes)
               SegAdr WorkSeg, WorkADR
           NEXT                         'do it again
           GOSUB ExtractKey             'sort & compress out data
                                        '  leave only additional info
           PassLo& = PassHi& + 1        'bump up to next group
           
           DestSeg = QPSSeg(Dest$)        're-establish Segs & Ptrs
           DestAdr = SADD(Dest$)
           WorkSeg = VARSEG(Work#(1, 1))
           WorkADR = VARPTR(Work#(1, 1))
       NEXT                             'do it again
    END IF
    IF LastTime THEN                            'hold rec 4991 for example
       PFD.Fno = P + 1 + (EachTime = Zero)      'add another pass?  only pass?
       PassHi& = PassLo& - 1 + LastTime
       FOR T& = PassLo& TO PassHi&
           PFD.Rno = T&
           FGet Handle, Dest$
           FOR Ky = 1 TO NumKeys
               IF NoCase THEN
                  IF Table(Ky, 2) > 0 THEN
                     MID$(Dest$, Table(Ky, 1) + 1, Table2(Ky)) = UCASE$(MID$(Dest$, Table(Ky, 1) + 1, Table2(Ky)))
                  END IF
               END IF
               BCopy DestSeg, DestAdr + Table(Ky, 1), WorkSeg, WorkADR, Table2(Ky), Zero
               WorkADR = WorkADR + Table2(Ky)
               SegAdr WorkSeg, WorkADR
           NEXT
           BCopy VARSEG(PFD), VARPTR(PFD), WorkSeg, WorkADR, 6, Zero
           WorkADR = AddUSI(WorkADR, PadBytes)
           SegAdr WorkSeg, WorkADR
       NEXT
       IF P = 1 THEN                    'will 1 pass do it?
          KeySort Work#(1, 1), KeyElSize, LastTime, Table3(1, 1), NumKeys
          TSSeg = VARSEG(Work#(1, 1))   'yes, we just sorted it
          TSAdr = VARPTR(Work#(1, 1)) + KeyBytes
          TDSeg = VARSEG(Work#(1, 1))
          TDAdr = VARPTR(Work#(1, 1))
          FOR N = 1 TO LastTime         'compress out all the data
              BCopy TSSeg, TSAdr, TDSeg, TDAdr, 4, Zero
              TSAdr = AddUSI(TSAdr, KeyElSize)
              SegAdr TSSeg, TSAdr
              TDAdr = AddUSI(TDAdr, 4)  'just save the record number
              SegAdr TDSeg, TDAdr
          NEXT
          KillFile (IndexFile$)
          FPutAH IndexFile$, Work#(1, 1), 4, LastTime
          GOTO LastStop
       ELSE
          GOSUB ExtractKey      'otherwise just extract it the same as above
       END IF
    END IF
   
   
    FOpen IndexFile$, Index             'get it ready to write
    REDIM Handles(1 TO TempFiles)       'the handle of each temp file
    REDIM FileRecs(0 TO TempFiles)      'total records in a temp file
    REDIM CountDown(0 TO TempFiles)     'records examined during a merge
    REDIM CountUp(0 TO TempFiles)       'records extracted during a merge
   
    Fini# = 0#: Done& = Zero: ReadCount = Zero: file = Zero: ReRead = Zero

    '----- first collection
    PerPass = PassRecs \ TempFiles
    FOR N = 1 TO TempFiles
        FOpen "FileSort." + LTRIM$(STR$(N)), Handles(N)
        FileRecs(N) = FLof(Handles(N)) \ 6
        SortRecs = SortRecs + MinInt(PerPass, FileRecs(N))
    NEXT
   
    REDIM Work#(1 TO XX, 1 TO SortRecs) 'clean the array Space
   
    Entry = Zero
    WorkSeg = VARSEG(Work#(1, 1))
    WorkADR = VARPTR(Work#(1, 1))
    FOR file = 1 TO TempFiles
        ReadCount = MinInt(PerPass, FileRecs(file))
        CountDown(file) = ReadCount
        GOSUB ReadWrite
    NEXT
   
Continue:
    KeySort Work#(1, 1), KeyElSize, SortRecs, Table3(1, 1), NumKeys
    FOR Rec = 1 TO SortRecs
        MWSeg = VARSEG(Work#(1, Rec))
        MWAdr = VARPTR(Work#(1, Rec)) + KeyBytes
        BCopy MWSeg, MWAdr, VARSEG(PFD), VARPTR(PFD), 6, Zero
        BCopy VARSEG(Fini#), VARPTR(Fini#), MWSeg, MWAdr, 6, Zero
       
        IF PFD.Fno > Zero THEN
           CountUp(PFD.Fno) = CountUp(PFD.Fno) + 1
           FPutT Index, PFD, 4
           Done& = Done& + 1
           IF Done& = NumRecs& THEN
              GOTO Finish
           END IF
        END IF

        IF CountUp(PFD.Fno) > Zero THEN
        IF CountUp(PFD.Fno) = FileRecs(PFD.Fno) OR CountUp(PFD.Fno) = CountDown(PFD.Fno) THEN         'was any limit reached???
          
           FOR file = 1 TO TempFiles
               IF CountUp(file) <= FileRecs(file) THEN
                  ReadCount = CountUp(file)
                  CountUp(file) = Zero
               ELSE
                  ReadCount = FileRecs(file)
               END IF
               
               IF (NOT ReRead) AND ReadCount THEN
                  Entry = Zero
                  WorkSeg = VARSEG(Work#(1, 1))
                  WorkADR = VARPTR(Work#(1, 1))
                  ReRead = -1
               END IF
               GOSUB ReadWrite
           NEXT
           IF ReRead THEN
              ReRead = Zero
              Entry = 0
              EXIT FOR
           END IF
        END IF
        END IF
    NEXT
    GOTO Continue

'***** Gosubs...
ExtractKey:
    IF PFD.Fno <= P THEN
       ThisTime = EachTime
    ELSE
       ThisTime = LastTime
    END IF
    IF ThisTime > 1 THEN
     KeySort Work#(1, 1), KeyElSize, ThisTime, Table3(1, 1), NumKeys
    END IF
     WorkSegEK1 = VARSEG(Work#(1, 1))
     WorkAdrEK1 = VARPTR(Work#(1, 1)) + KeyBytes
     WorkSegEK2 = VARSEG(Work#(1, 1))
     WorkAdrEK2 = VARPTR(Work#(1, 1))
     FOR N = 1 TO ThisTime
         BCopy WorkSegEK1, WorkAdrEK1, WorkSegEK2, WorkAdrEK2, 6, Zero
         WorkAdrEK1 = AddUSI(WorkAdrEK1, KeyElSize)
         SegAdr WorkSegEK1, WorkAdrEK1
         WorkAdrEK2 = AddUSI(WorkAdrEK2, 6)
         SegAdr WorkSegEK2, WorkAdrEK2
     NEXT
    FPutAH "FileSort." + LTRIM$(STR$(PFD.Fno)), Work#(1, 1), 6, ThisTime
    TempFiles = TempFiles + 1
RETURN

ReadWrite:
    DestSeg = QPSSeg(Dest$)
    DestAdr = SADD(Dest$)
    FileRecs(file) = FileRecs(file) - ReadCount
    FOR J = 1 TO ReadCount
        Entry = Entry + 1
        FGetT Handles(file), PFD, 6
        FGetR Handle, Dest$, PFD.Rno
        WorkSeg = VARSEG(Work#(1, Entry))
        WorkADR = VARPTR(Work#(1, Entry))
        FOR Ky = 1 TO NumKeys
            IF NoCase THEN
               IF Table(Ky, 2) > 0 THEN
                  MID$(Dest$, Table(Ky, 1) + 1, Table2(Ky)) = UCASE$(MID$(Dest$, Table(Ky, 1) + 1, Table2(Ky)))
               END IF
            END IF
            BCopy DestSeg, DestAdr + Table(Ky, 1), WorkSeg, WorkADR, Table2(Ky), Zero
            WorkADR = AddUSI(WorkADR, Table2(Ky))
        NEXT
        BCopy VARSEG(PFD), VARPTR(PFD), WorkSeg, WorkADR, 6, Zero
        WorkADR = AddUSI(WorkADR, PadBytes)
        SegAdr WorkSeg, WorkADR
    NEXT
RETURN

Finish:
    FOR N = 1 TO TempFiles
        FClose Handles(N)
        KillFile "FileSort." + LTRIM$(STR$(N))
    NEXT
    ERASE Handles               'the handle of each temp file
    ERASE FileRecs              'total records in a temp file
    ERASE CountDown             'records examined during a merge
    ERASE CountUp               'records extracted during a merge

    SetError Zero
    FClose Index
LastStop:
    FClose Handle
    ERASE Work#
    EXIT SUB


ErrExit4:
    IF ExitErr = Zero THEN ExitErr = WhichError
    FClose Handle
    ERASE Work#
ErrExit3:
    IF ExitErr = Zero THEN ExitErr = WhichError
    ERASE Table2
    ERASE Table3
ErrExit2:
    IF ExitErr = Zero THEN ExitErr = WhichError
    KillFile IndexFile$
ErrExit1:
    IF ExitErr = Zero THEN ExitErr = WhichError
    SetError ExitErr
    EXIT SUB

END SUB

FUNCTION FreeHandles% STATIC
  
    REDIM TestHandles(255)
    FOR Opener = 1 TO 255
        FOpen "NUL", TestHandles(Opener)
        IF DOSError THEN
           AvailableHandles = Opener - 1
           EXIT FOR
        END IF
    NEXT
    FOR Closer = 1 TO Opener
        FClose TestHandles(Closer)
    NEXT
    SetError 0
    ERASE TestHandles
    FreeHandles% = AvailableHandles
END FUNCTION

