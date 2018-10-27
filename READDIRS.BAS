'********** ReadDirs.Bas

'Utility to search through all levels of sub-directories for matching files

'Copyright (c) 1987 Ethan Winer


DEFINT A-Z

DECLARE SUB CleanUp ()
DECLARE FUNCTION DCount (DSpec$)
DECLARE SUB Display (T)
DECLARE FUNCTION FCount (FSpec$)
DECLARE SUB FileInfo (FSpec$, SEG ArrayEl)
DECLARE FUNCTION GetDir$ (Drive$)
DECLARE FUNCTION GetDrive% ()
DECLARE SUB DiskInfo (Drive$, BPS, SC, AC, TC)
DECLARE FUNCTION Pad$ (X)
DECLARE SUB ReadDirT (Spec$, BYVAL Segment, BYVAL Address)
DECLARE SUB ReadFileT (Spec$, BYVAL Segment, BYVAL Address)
DECLARE SUB SetDrive (Drive$)

'We SHOULD be using "SEG Element$" instead of "BYVAL Segment, BYVAL Address",
'in ReadFileT, but a "design decision" in QB 4 prevents this from working.


CLEAR , , 2000          'recursive subprogram Display needs extra stack space
CLS
Search$ = "*.*"         'used for finding all directory names
FullInfo = 1            'use zero to suppress full file info (and run faster)
DIM IArray(8)           'holds each file's size, date, time, and attribute

PRINT "This program searches an entire disk for a specified file."
PRINT "You may also use the DOS wildcards to search for a group of files."
PRINT
PRINT TAB(5); "Enter File Spec (ie A:*.Bas), or press Enter for *.* ";
LINE INPUT Spec$
IF Spec$ = "" THEN Spec$ = Search$

IF INSTR(Spec$, "\") THEN
   PRINT
   PRINT "Do not specify a directory.  This program searches ALL directories"
   PRINT "Press a key: ";
   CALL WaitKey
   RUN
END IF

CLS
LOCATE 25, 1: PRINT "Press any key to pause, or Escape to exit";
LOCATE 1, 1

IF MID$(Spec$, 2, 1) = ":" THEN                 'a drive was specified
   Drive$ = LEFT$(Spec$, 1)                     'isolate the drive letter
   Spec$ = MID$(Spec$, 3)                       'and the file specification
END IF

Original$ = GetDir$(Drive$)                     'save current directory
Drive = GetDrive%                               'and the current drive
IF LEN(Drive$) THEN SetDrive Drive$             'drive was given, change to it
CHDIR "\"                                       'start searching in the root

TotalCount = 0                                  'total number of files found
TabLevel = 5                                    'amount to tab when printing
Display TabLevel                                'display all matching files
CleanUp                                         'restore original path & drive

PRINT TotalCount; "File(s) Found"
DiskInfo Drive$, BytesPerSector, SectorsPerCluster, AvailableClusters, TotalClusters
PRINT

PRINT USING "##,###,### Bytes Free "; CLNG(BytesPerSector) * CLNG(SectorsPerCluster) * CLNG(AvailableClusters)
PRINT USING "##,###,### Total Disk Space "; CLNG(BytesPerSector) * CLNG(SectorsPerCluster) * CLNG(TotalClusters)

SUB CleanUp STATIC

    SHARED Drive, Drive$, Original$

    CHDIR Original$                             'back to original directory
    IF LEN(Drive$) THEN SetDrive CHR$(Drive)    'and drive

END SUB

SUB Display (T)

    SHARED Drive, Drive$, Spec$, Search$, TotalCount, FullInfo, IArray()

    IF T > 45 THEN                              '9 levels is enough, agreed?
       PRINT "Too many levels"
       EXIT SUB
    END IF

    CurntDir$ = SPACE$(64)                      'make room for directory name
    CurntDir$ = GetDir$("")                     'get directory, current drive
    CurntDir$ = RTRIM$(CurntDir$)               'strip trailing blanks

    FCnt = FCount(Spec$)                        'count matching files
                                                '  0 means count normal files
    TotalCount = TotalCount + FCnt              'add to the accumulator
    DIM FArray(FCnt)  AS STRING * 12            'dimension array accordingly
    ReadFileT Spec$, VARSEG(FArray$(0)), VARPTR(FArray$(0))  'read the names
                                                '  0 means read normal files
    IF LEN(Drive$) THEN                         'print the drive being used
       PRINT UCASE$(Drive$);                    '  if appropriate
    ELSE                                        '  else print original drive
       PRINT CHR$(Drive);
    END IF
    PRINT ":"; CurntDir$                        'print current directory

    FOR X = 0 TO FCnt - 1                       'for each file
        PRINT TAB(T); FArray$(X);               'tab in T spaces and print it

        IF FullInfo THEN                        'if they want the big picture
           FileInfo FArray$(X), IArray(0)
           'calculate the file size from two integer words
           LW& = IArray(6): IF LW& < 0 THEN LW& = LW& + 65536
           HW& = IArray(7): IF HW& < 0 THEN HW& = HW& + 65536
           PRINT USING "#########,"; LW& + 65536 * HW&;
           PRINT SPC(2);

           PRINT Pad$(IArray(1)); "/"; Pad$(IArray(2)); "/"; Pad$(IArray(0)); SPC(2);
           PRINT Pad$(IArray(3)); ":"; Pad$(IArray(4)); ":"; Pad$(IArray(5)); SPC(2);
           IF IArray(8) AND 1 THEN PRINT "Read-Only ";
           IF IArray(8) AND 2 THEN PRINT "Hidden ";
           IF IArray(8) AND 4 THEN PRINT "System ";
           IF IArray(8) AND 16 THEN PRINT "Subdirectory "; 'this isn't needed
           IF IArray(8) AND 32 THEN PRINT "Archive";
        END IF
        PRINT

        X$ = INKEY$                             'see if they pressed a key
        IF X$ <> "" THEN                        'pause on any keypress, or
           IF X$ = CHR$(27) THEN                'abort upon Escape, but first
              CleanUp                           'put everything back to normal
              END
           ELSE
              WHILE INKEY$ = "": WEND           'wait for another key
           END IF
        END IF
    NEXT

    PRINT : PRINT                               'add a couple of blank lines
    DCnt = DCount(Search$)                      'count dirs under this one
       
    IF DCnt THEN                                'if there are any, then

       DIM DArray(DCnt) AS STRING * 12          'dimension array for dir names
       ReadDirT Search$, VARSEG(DArray$(0)), VARPTR(DArray$(0))

                                                'get all dirs under this one
       IF CurntDir$ = "\" THEN                  'if we're in the root, use a
          Prefix$ = ""                          '  blank, otherwise use the
       ELSE                                     '  current directory
          Prefix$ = CurntDir$
       END IF

       FOR X = 0 TO DCnt - 1                    'for each directory,
           CHDIR Prefix$ + "\" + DArray$(X)     '  change to it
           Display T + 5                        '  and do this routine again
       NEXT

    END IF

END SUB

FUNCTION Pad$ (X)       'strip leading space, pad w/leading zero if needed

   IF LEN(STR$(X)) = 2 THEN
      Pad$ = "0" + RIGHT$(STR$(X), 1)
   ELSE
      Pad$ = RIGHT$(STR$(X), 2)
   END IF

END FUNCTION

