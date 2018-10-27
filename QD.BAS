'****************************** QD.BAS **************************************
'*               "QUICK DOS"  (C) 1988 Crescent Software
'*                        by Donald R. Malin
'****************************************************************************
'*
'* Compile Syntax:
'*     bc qd /o/s[/fpa];  (/fpa = Floating Point Alternate library for use
'*                                with BASIC 6 or later only)
'* Link Syntax:
'*     Link /e/noe/seg:400 _
'*       qd vertmenu viewfile [smallerr nocom nograph nolpt],,nul,pro;
'*
'*     "smallerr" and the "no" files above are not available with
'*     QuickBASIC 4.5 and are optional.
'*
'* Some hidden features:
'*      Alt R - RUN (execute) high-lighted file
'*      Alt S - SHELL, run high-lighted file and then return
'*      Alt F - Create List file containing the names of all marked files
'*      Uses 43 or 50 line screen modes if started in them.
'****************************************************************************

DEFINT A-Z

DECLARE SUB APrint0 (BYVAL Address, NumEls, StartChar, NumChars, Colr)
DECLARE SUB Box0 (UlRow, UlCol, LRRow, LRCol, Char, Colr)
DECLARE SUB CDir (Path$)
DECLARE SUB ClearScr0 (UlRow, UlCol, LRRow, LRCol, Colr)
DECLARE SUB DiskInfo (Drive$, BytesPerSector, SectorsPerCluster, AvailableClusters, TotalClusters)
DECLARE SUB Directory (LastDrvLtr, FileSpec$, DirCnt, Count)
DECLARE SUB Editor (X$, AnsLen, ScanCode, NumOnly, CapsOn, NClr, EClr, Row, Col)
DECLARE SUB FClose (Handle)
DECLARE SUB FCopy (Source$, Destination$, Buffer$, ErrCode)
DECLARE SUB FCreate (FileName$)
DECLARE SUB FOpen (FileName$, Handle)
DECLARE SUB FPut (Handle, Work$)
DECLARE SUB FSpecBox (Prompt$, FileSpec$)
DECLARE SUB FunkBox ()
DECLARE SUB GetVMode (Mode, Page, PageSize, Rows, Columns)
DECLARE SUB HideCursor ()
DECLARE SUB InitOpts (Rows, SortFlag, FileSpec$, Cnf AS ANY)
DECLARE SUB KillFile (DelFil$)
DECLARE SUB LowASCII (Text$)
DECLARE SUB Lower (Work$)
DECLARE SUB Message (Mesg$, Lne, Clr)
DECLARE SUB MScrnSave (UlRow, UlCol, LRRow, LRCol, SEG BufAdr)
DECLARE SUB MScrnRest (UlRow, UlCol, LRRow, LRCol, SEG BufAdr)
DECLARE SUB MPaintBox (UlRow, UlCol, LRRow, LRCol, Colr)
DECLARE SUB MQPrint (Text$, Colr)
DECLARE SUB PrmTxt (Prompt$, Answer$, AnSize)
DECLARE SUB ReadFileI (BYVAL ArrSt)
DECLARE SUB ReadDir (BYVAL ArrSt)
DECLARE SUB RemCtrl (Text$, Replace$)
DECLARE SUB ScrollU (UlRow%, UlCol%, BrRow%, BrCol%, Lines%, Page%)
DECLARE SUB SetDrive (Drive$)
DECLARE SUB ShowCursor ()
DECLARE SUB Sorter (Array$(), DirCnt, Count, SortFlag)
DECLARE SUB SortNum (Array$(), Num&(), StrtLst, EndList)
DECLARE SUB SortStrings (Array$(), XtnFlag, StrtLst, EndList)
DECLARE SUB SpecChars (Text$, HiBit)
DECLARE SUB StuffBuf (Keys$)
DECLARE SUB TextCursor (Var1, Var2)
DECLARE SUB VertMenu (Item$(), Choice, MaxLen, BoxBot, Ky$, Action, Cnf AS ANY)
DECLARE SUB ViewFile (FileName$, NumChars, Rows, Clr, HiBit, Action)
DECLARE SUB WaitKey ()

DECLARE FUNCTION ArraySize% (UlRow, UlCol, LRRow, LRCol)
DECLARE FUNCTION Date2Num% (Dat$)
DECLARE FUNCTION DCount% (DirSpec$)
DECLARE FUNCTION DiskRoom& (Drive$)
DECLARE FUNCTION DosError% ()
DECLARE FUNCTION Exist% (FileSpec$)
DECLARE FUNCTION ExpandTab$ (Text$, NumSpaces)
DECLARE FUNCTION FCount% (FileSpec$)
DECLARE FUNCTION FileSize& (FileName$)
DECLARE FUNCTION FUsing$ (Number$, Mask$)
DECLARE FUNCTION GetDir$ (Drive$)
DECLARE FUNCTION GetDrive% ()
DECLARE FUNCTION InCount% (LookIn$, Char$)
DECLARE FUNCTION LastDrive% ()
DECLARE FUNCTION MakeStr$ (Num&)
DECLARE FUNCTION MaxInt% (Arg1, Arg2)
DECLARE FUNCTION MinLong& (Arg1&, Arg2&)
DECLARE FUNCTION MinInt% (Arg1, Arg2)
DECLARE FUNCTION Monitor% ()
DECLARE FUNCTION OneColor% (Bg, Fg)
DECLARE FUNCTION ParsPath$ (FileSpec$)
DECLARE FUNCTION PeekBuf% ()
DECLARE FUNCTION QInstr% (Start, Work$, Srch$)
DECLARE FUNCTION QPValL& (Number$)
DECLARE FUNCTION ReadTest% (Drive$)
DECLARE FUNCTION TestDrv% (Path$, WriteFlg, Rows)
DECLARE FUNCTION Time2Num& (Tme$)
DECLARE FUNCTION Valid% (FileSpec$)
DECLARE FUNCTION WhichError% ()
DECLARE FUNCTION WriteTest% (Drive$)


CONST Crescent$ = " Full Moon Software, 34 Cedar Vale Drive, New Milford, CT  06776  860-350-8188 "
CONST PAKey$ = "Press any key to continue..."
CONST RunTbl$ = ".bat .exe .com "               'Executable file extensions
CONST F1 = 59
CONST F2 = 60
CONST F3 = 61
CONST CtrlF4 = 97
CONST F5 = 63
CONST F6 = 64
CONST F7 = 65
CONST F8 = 66
CONST F9 = 67
CONST F10 = 68
CONST AltF10 = 113
CONST AltC = 46
CONST AltM = 50
CONST AltF = 33
CONST AltR = 19
CONST AltS = 31
CONST Cl = 7

DIM SHARED Cmd$
Cmd$ = UCASE$(COMMAND$)

IF INSTR(Cmd$, "?") OR INSTR(Cmd$, "HELP") THEN
   PRINT "Valid command line options:"
   PRINT "  /H - High resolution."
   PRINT "  /B - Force monochrome display."
   PRINT "  /N - Sort by file name."
   PRINT "  /E - Sort by file extension."
   PRINT "  /S - Sort by file size."
   PRINT "  /D - Sort by file date."
   PRINT
   PRINT "Unlisted features:"
   PRINT "  Alt F - Create list file of marked file names."
   PRINT "  Alt R - Run executable file."
   PRINT "  Alt S - Shell to executable file."
   END
END IF


'$INCLUDE: 'DefCnf.BI'
'$INCLUDE: 'SetCnf.BI'

SCREEN 0
GetVMode Mode, 0, 0, Rows, 0                    'Get the number of screen rows
DosRows = Rows

ScSize = Rows * 80                              'Calc size of screen buffers
REDIM DosScr(ScSize + 1)                        'Dos Screen Buffer
REDIM Array$(1)                                 'Directory/File Name array

MScrnSave 1, 1, Rows, 80, DosScr(0)             'Save the Dos Screen
Row = CSRLIN                                    '  "   "  Cursor Row
Col = POS(0)                                    '  "   "  Cursor Column
    
CLS                                             'Clear the screen
LOCATE , , 0                                    'Turn the cursor off
  
CrLf$ = CHR$(13) + CHR$(10)
Total$ = SPACE$(12)                             'File Length display field
Prompt$ = "File Specification:"                 'Prompt for the File Spec Box
BFree$ = SPACE$(12)                             'Bytes free Display Field
LastDrvLtr = LastDrive

'*** Initialize Flags
Action = 1                                      'Multi-Tasking Flag `VertMenu'
GetFree = 1                                     'Get Free Space Flag

InitOpts Rows, SortFlag, FileSpec$, Cnf         'parse the command line
IF Rows = 50 AND DosVer% >= 1000 THEN           '50 Line mode uses 7 pixels
   ScPxLines = 7                                '  per character for mouse
ELSE                                            '43 and 25 modes use 8
   ScPxLines = 8
END IF

FunkBox                                         'Display the Function Key Box

LOCATE 24, 47                                   'Display the Bytes free
MQPrint "Bytes Free = ", 10                     '  message

TextCursor -2, -2                               'Set up the mouse cursor
ShowCursor                                      'turn the mouse cursor on

DirFlag = -1



'----- Main Loop
DO

    IF DirFlag THEN                             'Is Directory Flag Set?
                                                'Initialize -
       DirCnt = 0                               '  # of drive/directory names
       FilCnt = 0                               '  # of file names
       Total& = 0                               '  bytes of marked files
       
       Message "Loading Directory...", Rows, 10
                                                'Count the matching files
                                                'Load Array$() with Directory
       Directory LastDrvLtr, FileSpec$, DirCnt, FilCnt
       FSpecBox Prompt$, FileSpec$
             
       IF FilCnt OR DirCnt THEN                 'Are there any
          HideCursor
          ClearScr0 4, 1, Rows, 44, Cl          'Clear old window
          ShowCursor
       END IF
       Message Crescent$, Rows, 112             'Clear Message line - Rows
       DirFlag = 0                              'Clear Flag
    END IF
       
    Path$ = ParsPath$(FileSpec$)                'Parse out the Path Spec.

    IF FilCnt OR DirCnt THEN

       IF SortFlag THEN                         'See if we have to sort
          Message "Sorting Files...", Rows, 10
                                                'Sort Files according to Flag
          Sorter Array$(), DirCnt, FilCnt, SortFlag
          OldSort = SortFlag                    'Save the flag as the current
          SortFlag = 0                          '  sort method
          Message Crescent$, Rows, 112          'Clear Line Rows
       END IF
          
       IF Total& THEN DispTotal = -1            'Set flag to display new total

       IF GetFree THEN                          'If flag set to get free disk
          LSET BFree$ = MakeStr$(DiskRoom&("")) '  space, get and display it
          LOCATE 24, 60
          MQPrint BFree$, 10
          GetFree = 0
       END IF
                                               
       Wdth = 40                                'Set VertMenu window size

       '----- Menu display loop
       DO
           IF Action = 1 THEN DispTotal = -1    'If redispalying window, set
                                                '  flag to redisplay total

           LOCATE 4, 1, 0                       'Position the Cursor

           '*****************************************************************
           '* Call VertMenu in Multi-Tasking Mode.  Specifying -
           '* `Action' = 1, Draw Window and return if no key pressed
           '*          = 2, ReDraw Choices, Check Keyboard and return
           '*          = 3, Just check Keyboard and return. (default after 1)
           '*          = 4, Action was taken by User
           '*****************************************************************
           BoxBot = Rows - 1
           VertMenu Array$(), Choice, Wdth, BoxBot, Ky$, Action, Cnf


           IF DispTotal THEN                    'Redisplay the total if
              IF Total& THEN                    '  requested
                 LSET Total$ = MakeStr$(Total&)
                 Message "Combined File Size = " + Total$, Rows, 10
              ELSE                              'Otherwise redisplay the
                 Message Crescent$, Rows, 112   '  Crescent message
              END IF
              DispTotal = 0                     'Reset the flag
           END IF

           IF Cnf.Mouse THEN                    'If there is a mouse, see if
              CALL GetCursor(X, Y, Button)      '  a button was pressed
           END IF
           IF Button AND 1 THEN
              MRow = (Y \ ScPxLines) + 1        'Convert X, Y to Row and Column
              MCol = (X \ 8) + 1
                                                'Was button pressed on the
                                                '  prompt box?
              IF MRow > 8 AND MRow < 23 AND MCol > 47 AND MCol < 78 THEN
                 SELECT CASE MRow
                    CASE 9                      '[F1] Edit line
                       Ky$ = CHR$(0) + CHR$(F1)
                    CASE 10                     '[F2] Copy line
                       Ky$ = CHR$(0) + CHR$(F2)
                    CASE 11                     '[F3] Move line
                       Ky$ = CHR$(0) + CHR$(F3)
                    CASE 12                     '[Ctrl F4] Delete line
                       Ky$ = CHR$(0) + CHR$(CtrlF4)
                    CASE 14                     '[F6] Sort by name line
                       Ky$ = CHR$(0) + CHR$(F6)
                    CASE 15                     '[F7] Sort by extension line
                       Ky$ = CHR$(0) + CHR$(F7)
                    CASE 16                     '[F8] Sort by size line
                       Ky$ = CHR$(0) + CHR$(F8)
                    CASE 17                     '[F9] Sort by date line
                       Ky$ = CHR$(0) + CHR$(F9)
                    CASE 18                     '[F10] Display file line
                       Ky$ = CHR$(0) + CHR$(F10)
                    CASE 20                     'Enter line
                       Ky$ = CHR$(13)
                       Action = 4
                    CASE 21                     'Mark or Clear line
                       IF MCol = 53 THEN Ky$ = CHR$(0) + CHR$(AltM)
                       IF MCol = 55 THEN Ky$ = CHR$(0) + CHR$(AltC)
                    CASE 22                     'Escape line
                       Ky$ = CHR$(27)
                       Action = 4
                    CASE ELSE
                       Action = 3
                 END SELECT
                                                'Button pressed on edit window
              ELSEIF MRow < 3 AND MCol > 23 THEN
                 Ky$ = CHR$(0) + CHR$(F1)
              END IF

           END IF

           IF (Ky$ = CHR$(13) OR Ky$ = CHR$(32)) AND Choice > DirCnt THEN
              '*** If user pressed Enter
                                                        'Get the file's Size
              Size& = QPValL&(MID$(Array$(Choice), 14, 8))
              IF Size& = 0 THEN Size& = 1
              IF MID$(Array$(Choice), Wdth, 1) = "û" THEN  'Was File Marked?
                 MID$(Array$(Choice), Wdth, 1) = " "    'UnMark file
                 Total& = Total& - Size&                'Remove from Total
              ELSE                                      'Otherwise,
                 MID$(Array$(Choice), Wdth, 1) = "û"    'Mark file
                 Total& = Total& + Size&                'Add to Total
              END IF
              DispTotal = -1
              Action = 2                        'Set Flag to ReDisplay
           END IF
                                                'Check for User Action
       LOOP UNTIL Action = 4 OR LEN(Ky$) > 1
       Ky = 0                                   'Extract Second Key code
       IF LEN(Ky$) = 2 THEN Ky = ASC(RIGHT$(Ky$, 1))

    ELSE                                        'No Matching Files(FilCnt = 0)
       HideCursor
       ClearScr0 4, 1, Rows, 44, Cl             'Clear old window
       ShowCursor

       Message "No Files Found", Rows, 12       'Inform the user
       Ky = F1                                  'Force [F1]-Edit key

    END IF

    '----- Handle keys not used by VertMenu
    IF Ky$ = CHR$(13) THEN                      'Directory Selection
       NewDir$ = LTRIM$(RTRIM$(Array$(Choice))) 'Get the directory name

       FOR N = LEN(FileSpec$) TO 1 STEP -1
           IF MID$(FileSpec$, N, 1) = "\" OR MID$(FileSpec$, N, 1) = ":" THEN EXIT FOR
       NEXT
       SrchSpec$ = MID$(FileSpec$, N + 1)
                                      
       IF INSTR(NewDir$, "[-") THEN             'Look for a Drive icon
          DrvLtr$ = MID$(NewDir$, 3, 1) + ":"   'Make a new drive spec.
          IF TestDrv(DrvLtr$, 0, Rows) THEN     'Test the drive
             FileSpec$ = DrvLtr$ + SrchSpec$    'Make new file spec.
             GetFree = 1                        'Set flag to get free space
          END IF
       ELSE
          FileSpec$ = NewDir$ + "\" + SrchSpec$ 'Recompose the new file spec
       END IF                                   '  with the new directory

       TempChoice = Choice                      'Save the current choice #
       Choice = 1                               'Set choice# to 1
       Action = 1                               'Set action flag to re-draw
       DirFlag = -1                             'Set directory flag to read
       SortFlag = OldSort                       'Set sort flag
    END IF

    SELECT CASE Ky                              'Handle extended keys

       '----- [F1] Edit File Spec.
       CASE F1
          FileName$ = ""
          LOCATE 2, 3, 1
          TempSpec$ = FileSpec$
          PrmTxt Prompt$, FileSpec$, 40
          LOCATE , , 0
          IF LEN(FileSpec$) = 0 THEN
             FileSpec$ = TempSpec$
             FSpecBox Prompt$, FileSpec$
          ELSE
             IF INSTR(FileSpec$, ":") THEN
                IF NOT TestDrv(LEFT$(FileSpec$, 2), 0, Rows) THEN FileSpec$ = TempSpec$
             END IF
             Total& = 0
             Action = 1
             DirFlag = -1
             SortFlag = OldSort
             GetFree = -1
          END IF
          
       '----- [F2] Copy, [F3] Move
       CASE F2, F3
          IF Total& THEN
             QDMove = 0
             CpyPrmt$ = "Copy to - "
             IF Ky = F3 THEN
                QDMove = -1
                CpyPrmt$ = "Move to - "
             END IF

             DO
                LOCATE 2, 3
                PrmTxt CpyPrmt$, Dst$, 40

                IF LEN(Dst$) = 2 AND RIGHT$(Dst$, 1) = ":" THEN
                   IF ASC(UCASE$(Dst$)) <= LastDrive% THEN EXIT DO
                END IF
                There = DCount(Dst$ + "*.*")
                IF There = 0 AND LEN(Dst$) THEN
                   Message Dst$ + " does not exist!", Rows, 12
                END IF
             LOOP UNTIL There OR LEN(Dst$) = 0

             Dest$ = Dst$
             RtChr$ = RIGHT$(Dest$, 1)
             IF LEN(Dest$) AND RtChr$ <> ":" AND RtChr$ <> "\" THEN
                Dest$ = Dest$ + "\"
             END IF

            
             IF LEN(Dest$) AND Dest$ <> Path$ THEN
                HideCursor
                ClearScr0 4, 1, Rows, 44, Cl      'Clear old window
                ShowCursor
                Bigs = 0
                Drv$ = ""
                IF INSTR(Dest$, ":") THEN Drv$ = LEFT$(Dest$, 2)
                IF TestDrv(Drv$, -1, Rows) THEN
                   Room& = DiskRoom&(Drv$)
                   DiskInfo Drv$, BytesPerSector, SectorsPerCluster, AvailableClusters, TotalClusters
                   ClusterSize = BytesPerSector * SectorsPerCluster

                   IF FRE("") > 32356 THEN
                      BuffLen = 32256
                   ELSE
                      BuffLen = FRE(0) - 612
                      BuffLen = (BuffLen \ 512) * 512
                   END IF
                   Buffer$ = SPACE$(BuffLen)

                   FOR N = DirCnt + 1 TO DirCnt + FilCnt
                       IF PeekBuf% = 27 THEN
                          Bs$ = INKEY$
                          EXIT FOR
                       END IF
                       IF MID$(Array$(N), Wdth, 1) = "û" THEN
                          Cpy$ = LEFT$(Array$(N), 12)
                          Size& = QPValL&(MID$(Array$(N), 14, 8))
                          FSize& = ((Size& \ ClusterSize) - (Size& MOD ClusterSize <> 0)) * ClusterSize

                          IF Room& < 2000000 THEN
                             IF Exist(Dest$ + Cpy$) THEN
                                DSize& = FileSize&(Dest$ + Cpy$)
                                DSize& = ((DSize& \ ClusterSize) - (DSize& MOD ClusterSize <> 0)) * ClusterSize
                                Room& = Room& + DSize&
                             END IF
                          END IF

                          IF FSize& <= Room& THEN
                             Operation$ = "Copying "
                             IF QDMove THEN Operation$ = "Moving "
                             Again = 0
                             DO
                                 Message Operation$ + Path$ + Cpy$ + "  to  " + Dest$, 4, 10

                                 FCopy Path$ + Cpy$, Dest$ + Cpy$, Buffer$, ErrCode
                                 SELECT CASE WhichError%
                                    CASE 0
                                       IF QDMove THEN KILL Path$ + Cpy$
                                       Room& = Room& - FSize&
                                       MID$(Array$(N), Wdth, 1) = " "
                                       Total& = Total& - Size&
                                    CASE 53, 64, 75, 76
                                       Message Dest$ + " path not found!", 4, 10
                                       EXIT FOR
                                    CASE 61
                                       Message "Disk full on " + Dest$, 4, 10
                                       EXIT FOR
                                    CASE 70
                                       Message Dest$ + Cpy$ + " is a READ ONLY file!  Press any key.", 4, 10
                                       WaitKey
                                    CASE 25, 57, 71, 72
                                       Message "Drive " + Drv$ + " Not Ready!  Press ``R'' to retry, any other key to quit.", 4, 10
                                       K$ = UCASE$(INPUT$(1))
                                       IF K$ = "R" THEN
                                          Again = -1
                                       ELSE
                                          EXIT FOR
                                       END IF
                                    CASE ELSE
                                 END SELECT
                             LOOP WHILE Again
                          ELSE
                             IF Bigs + 5 > Rows - 1 THEN
                                HideCursor
                                ScrollU 5, 1, Rows - 1, 46, 1, 0
                                ShowCursor
                                Bigs = Bigs - 1
                             END IF
                             LOCATE 5 + Bigs, 1
                             MQPrint LEFT$(Cpy$ + " can't fit on " + Drv$, 44), 12
                             Bigs = Bigs + 1
                          END IF
                       END IF
                   NEXT
                   Buffer$ = ""
                END IF
                IF Bigs OR DosError THEN
                   Message PAKey$, Rows, 10
                   Bs$ = INPUT$(1)
                END IF
                Message "", 4, 2
                HideCursor
                ClearScr0 4, 1, Rows, 44, Cl      'Clear old window
                ShowCursor
             END IF
             FSpecBox Prompt$, FileSpec$
             Action = 1
             DirFlag = QDMove
             GetFree = -1
             IF DirFlag THEN
                SortFlag = OldSort
             END IF
          ELSE
             Message "No files marked!  " + PAKey$, Rows, 10
             Bs$ = INPUT$(1)
             Message Crescent$, Rows, 112
          END IF

       '----- [Ctrl] [F4] Delete
       CASE CtrlF4
          IF Total& THEN
             HideCursor
             ClearScr0 4, 1, Rows, 44, Cl       'Clear old window
             ShowCursor
             FOR N = DirCnt + 1 TO FilCnt + DirCnt
                 K$ = INKEY$
                 IF K$ = CHR$(27) THEN EXIT FOR
                 IF MID$(Array$(N), Wdth, 1) = "û" THEN
                    DelFil$ = Path$ + LEFT$(Array$(N), 12)
                    Message "Deleting ``" + DelFil$ + "''", 4, 10
                    KillFile DelFil$
                    IF DosError THEN
                       Message "File is marked READ ONLY!  " + PAKey$, Rows, 12
                       Bs$ = INKEY$
                    END IF
                 END IF
             NEXT
             FSpecBox Prompt$, FileSpec$
             Action = 1
             Choice = 1
             DirFlag = -1
             SortFlag = OldSort
             GetFree = -1
          ELSE
             Message "No files marked!  " + PAKey$, Rows, 10
             Bs$ = INPUT$(1)
             Message Crescent$, Rows, 112
          END IF

       '----- [F5] Toggle Detail
       'CASE F5

       '----- [F6] Sort by Name
       CASE F6
          SortFlag = 1
          Action = 2
             
       '----- [F7] Sort by Extension
       CASE F7
          SortFlag = 2
          Action = 2

       '----- [F8] Sort by Size
       CASE F8
          Action = 2
          SortFlag = 3

       '----- [F9] Sort by Date
       CASE F9
          Action = 2
          SortFlag = 4

       '----- [F10] Show File Contents
       CASE F10, AltF10
          IF Choice > DirCnt THEN
             HideCursor
             HiBit = (Ky = AltF10)
             SELECT CASE Monitor
                CASE 3, 5, 7, 9, 10, 11, 12
                   VClr = 23
                CASE ELSE
                   VClr = 2
             END SELECT
             LOCATE 1, 1
             ViewFile Path$ + LEFT$(Array$(Choice), 12), 78, Rows - 2, VClr, HiBit, 0
             ShowCursor
          END IF

       '----- Clear/Mark ALL Files
       CASE AltC, AltM
          Total& = 0
          FOR N = DirCnt + 1 TO DirCnt + FilCnt
              IF Ky = AltC THEN
                 MID$(Array$(N), Wdth, 1) = " "
                 DispTotal = -1
              ELSE
                 MID$(Array$(N), Wdth, 1) = "û"
                 Total& = Total& + QPValL&(MID$(Array$(N), 14, 8))
              END IF
          NEXT
          Action = 2

       '----- Create List File
       CASE AltF
          LOCATE 2, 3
          PrmTxt "Create List File:", Lst$, 60
          IF LEN(Lst$) AND Valid%(Lst$) THEN
             FCreate Lst$
             IF DosError% THEN
                Message "Unable to create file " + Lst$, Rows, 10
             ELSE
                FOpen Lst$, Handle
                FOR N = DirCnt + 1 TO DirCnt + FilCnt
                    IF MID$(Array$(N), Wdth, 1) = "û" THEN
                       FPut Handle, Path$ + RTRIM$(LEFT$(Array$(N), 12)) + CrLf$
                    END IF
                NEXT
                FClose Handle
                Message "File ``" + Lst$ + "'' Created.  Press any key to continue.", Rows, 10
                WaitKey
                Action = 1
                IF FCount(FileSpec$) <> FilCnt THEN
                   DirFlag = -1
                   SortFlag = OldSort
                END IF
             END IF
          END IF

       '----- Run/Shell an executable file
       CASE AltR, AltS
          FilName$ = RTRIM$(LEFT$(Array$(Choice), 12))
          IF INSTR(RunTbl$, RIGHT$(FilName$, 4)) THEN
             IF Ky = AltS THEN
                REDIM ProgScr(Rows * 80)          'Program Screen Buffer
                MScrnSave 1, 1, Rows, 80, ProgScr(0)
                HideCursor
                CLS
                IF FRE(-1) > 10000 THEN SHELL FilName$
                MScrnRest 1, 1, Rows, 80, ProgScr(0)
                ERASE ProgScr
                ShowCursor
                Action = 1
                IF FCount(FileSpec$) <> FilCnt THEN
                   DirFlag = -1
                   SortFlag = OldSort
                ELSE
                   Action = 2
                END IF
             ELSE
                StuffBuf FilName$ + CHR$(13)
                Ky$ = CHR$(27)
                Total& = 0
             END IF
          END IF

       CASE ELSE
    END SELECT

    '----- See if files are marked befor proceeding
    IF Total& AND (Ky$ = CHR$(27) OR Ky$ = CHR$(13) OR (Ky = F1 AND XCode <> 0)) THEN
       Message "Files are marked!  Continue Anyway? [ Y, N ]", Rows, 12
       K$ = UCASE$(INPUT$(1))
       IF K$ <> "Y" THEN
          IF Ky$ = CHR$(13) THEN Choice = TempChoice
          FileSpec$ = TempSpec$
          Ky$ = ""
          GetFree = 0
          Action = 2
          DirFlag = 0
          SortFlag = 0
       END IF
    END IF

LOOP UNTIL Ky$ = CHR$(27)                   'Go back unless Escape pressed

WIDTH , DosRows
MScrnRest 1, 1, DosRows, 80, DosScr(0)          'Restore the DOS Screen
LOCATE Row, Col                                 'Re-locate the cursor
                                                'Quit
CALL HideCursor
END

SUB Directory (LastDrvLtr, FileSpec$, DirCnt, FilCnt) STATIC

    SHARED Array$(), ErrCode, Rows
    ErrCode = 0

    Drv = INSTR(FileSpec$, ":")
    IF Drv THEN
       Drive$ = UCASE$(LEFT$(FileSpec$, 2))
       CALL SetDrive(Drive$)
       D = GetDrive%
       Drive$ = CHR$(D) + ":"
    ELSE
       D = GetDrive%
       Drive$ = CHR$(D) + ":"
    END IF
   
    FOR N = LEN(FileSpec$) TO Drv + 1 STEP -1
        IF MID$(FileSpec$, N, 1) = "\" THEN EXIT FOR
    NEXT
    Path$ = UCASE$(MID$(FileSpec$, Drv + 1, N - Drv))
    IF RIGHT$(Path$, 1) <> "\" THEN Path$ = ""
    IF LEN(Path$) > 1 THEN Path$ = LEFT$(Path$, LEN(Path$) - 1)


                                                'Are we backing up one level?
    IF INSTR(FileSpec$, "..") AND Path$ <> "\" THEN
       CDir ".."
       Path$ = ""
    END IF


    Drct$ = GetDir$("")
    IF LEN(Drct$) > 1 THEN
       CurPath$ = Drct$
       IF LEN(Path$) AND Path$ <> LastPath$ AND Path$ <> CurPath$ THEN
          CDir Path$
       END IF
    ELSEIF LEN(Path$) AND Path$ <> LastPath$ THEN
       CDir Path$
    END IF

    IF DosError THEN
       WHILE INKEY$ <> "": WEND
       Message UCASE$(Path$) + " does not exist!  " + PAKey$, Rows, 12
       K$ = INPUT$(1)
    END IF


    Drct$ = GetDir$("")
    Path$ = ""
    IF LEN(Drct$) > 1 THEN Path$ = Drct$
    LastPath$ = MID$(Path$, 2)


    SrchSpec$ = RTRIM$(MID$(FileSpec$, N + 1))
    IF LEN(SrchSpec$) = 0 THEN SrchSpec$ = "*.*"
    FileSpec$ = Drive$ + Path$ + "\" + SrchSpec$

    Prompt$ = "File Specification:"             'Display the File Spec Box
    FSpecBox Prompt$, FileSpec$

    Drives = LastDrvLtr - 65
    DirSpec$ = Path$ + "\*.*"
    DirCnt = DCount(DirSpec$) + Drives + 1
    IF DirCnt > 1000 THEN DirCnt = 1000
    REDIM DirAr$(DirCnt + 1)
    FOR N = 1 TO DirCnt + 1
        DirAr$(N) = SPACE$(65)
    NEXT
    
    IF LEN(Path$) THEN
       DirAr$(1 + Drives) = DirSpec$
       ReadDir BYVAL VARPTR(DirAr$(1 + Drives))
       LSET DirAr$(1) = ".."
       SortStrings DirAr$(), 0, 2 + Drives, DirCnt
       PutIt = 2
    ELSE
       DirCnt = DirCnt - 1
       DirAr$(Drives) = DirSpec$
       ReadDir BYVAL VARPTR(DirAr$(Drives))
       SortStrings DirAr$(), 0, Drives + 1, DirCnt
       PutIt = 1
    END IF

    FOR N = 65 TO LastDrvLtr
        IF N <> D THEN
           DirAr$(PutIt) = "[-" + CHR$(N) + "-]"
           PutIt = PutIt + 1
        END IF
    NEXT

    '*** Get File Names
    FilCnt = FCount(SrchSpec$)
    IF FilCnt > 2000 THEN FilCnt = 2000
    REDIM Array$(FilCnt + DirCnt + 2)

    FOR N = 1 TO FilCnt + DirCnt                   'make room for the names
        Array$(N) = SPACE$(40)
        MID$(Array$(N), 39) = "³"
    NEXT

    Array$(DirCnt) = SrchSpec$
    ReadFileI VARPTR(Array$(DirCnt))                'get the file names
    Array$(DirCnt) = SPACE$(40)

    FOR N = DirCnt + 1 TO DirCnt + FilCnt
        Lower Array$(N)
    NEXT

    FOR N = 1 TO DirCnt
        LSET Array$(N) = DirAr$(N)
    NEXT
    ERASE DirAr$

END SUB

SUB FSpecBox (Prompt$, FileSpec$) STATIC
 
    Mon = Monitor
    IF INSTR(Cmd$, "/B") THEN Mon = 1
    SELECT CASE Monitor
       CASE 3, 5, 7, 9, 10, 11, 12
          Clr = 30
       CASE ELSE
          Clr = 10
    END SELECT
             
    LOCATE 1, 1
    MQPrint CHR$(201) + STRING$(78, 205) + CHR$(187), Clr
    LOCATE 2, 1
    MQPrint CHR$(186) + SPACE$(78) + CHR$(186), Clr
    LOCATE 3, 1
    MQPrint CHR$(200) + STRING$(78, 205) + CHR$(188), Clr
   
    LOCATE 2, 3
    MQPrint Prompt$ + " ", Clr

    EdStrt = 4 + LEN(Prompt$)
    EdLen = 78 - EdStrt + 1
    Prmt$ = SPACE$(EdLen)

    CALL MPaintBox(2, EdStrt, 2, 78, 112)
    LOCATE 2, EdStrt
    LSET Prmt$ = FileSpec$
    MQPrint Prmt$, 112

END SUB

SUB FunkBox

    Mon = Monitor
    IF INSTR(Cmd$, "/B") THEN Mon = 1
   
    SELECT CASE Mon
       CASE 3, 5, 7, 9, 10, 11, 12
          LClr = 23
          Clr = 30
       CASE ELSE
          LClr = 2
          Clr = 10
    END SELECT
       
    LOCATE 5, 47
    MQPrint CHR$(218) + STRING$(32, 196) + CHR$(191), LClr
    LOCATE 6, 47
    MQPrint CHR$(179) + "  Q U I C K    D O S   ``QD''   " + CHR$(179), LClr
    LOCATE 7, 47
    MQPrint CHR$(179) + "  (C) 1988 Crescent Software    " + CHR$(179), LClr
    CALL MPaintBox(6, 48, 7, 78, Clr)
    LOCATE 8, 47
    MQPrint CHR$(195) + STRING$(32, 196) + CHR$(180), LClr
    LOCATE 9, 47
    MQPrint CHR$(179) + " F1 - EDIT File Specification   " + CHR$(179), LClr
    CALL MPaintBox(9, 49, 9, 50, 112)
    CALL MPaintBox(9, 54, 9, 57, Clr)
    LOCATE 10, 47
    MQPrint CHR$(179) + " F2 - COPY Selected Files       " + CHR$(179), LClr
    CALL MPaintBox(10, 49, 10, 50, 112)
    CALL MPaintBox(10, 54, 10, 57, Clr)
    LOCATE 11, 47
    MQPrint CHR$(179) + " F3 - MOVE Selected Files       " + CHR$(179), LClr
    CALL MPaintBox(11, 49, 11, 50, 112)
    CALL MPaintBox(11, 54, 11, 57, Clr)
    LOCATE 12, 47
    MQPrint CHR$(179) + " Ctrl F4 - DELETE Selected Files" + CHR$(179), LClr
    CALL MPaintBox(12, 49, 12, 52, 112)
    CALL MPaintBox(12, 54, 12, 55, 112)
    CALL MPaintBox(12, 59, 12, 64, Clr)
    LOCATE 13, 47
'   MQPrint CHR$(179) + " F5 - Toggle DETAIL Display     " + CHR$(179), LClr
    MQPrint CHR$(179) + "                                " + CHR$(179), LClr
'   CALL MPaintBox(13, 49, 13, 50, 112)
    CALL MPaintBox(13, 61, 13, 66, Clr)
    LOCATE 14, 47
    MQPrint CHR$(179) + " F6 - Sort by File NAME         " + CHR$(179), LClr
    CALL MPaintBox(14, 49, 14, 50, 112)
    CALL MPaintBox(14, 67, 14, 70, Clr)
    LOCATE 15, 47
    MQPrint CHR$(179) + " F7 - Sort by File EXTENSION    " + CHR$(179), LClr
    CALL MPaintBox(15, 49, 15, 50, 112)
    CALL MPaintBox(15, 67, 15, 75, Clr)
    LOCATE 16, 47
    MQPrint CHR$(179) + " F8 - Sort by File SIZE         " + CHR$(179), LClr
    CALL MPaintBox(16, 49, 16, 50, 112)
    CALL MPaintBox(16, 67, 16, 70, Clr)
    LOCATE 17, 47
    MQPrint CHR$(179) + " F9 - Sort by File DATE         " + CHR$(179), LClr
    CALL MPaintBox(17, 49, 17, 50, 112)
    CALL MPaintBox(17, 67, 17, 70, Clr)
    LOCATE 18, 47
    MQPrint CHR$(179) + " F10 - DISPLAY File Contents    " + CHR$(179), LClr
    CALL MPaintBox(18, 49, 18, 51, 112)
    CALL MPaintBox(18, 55, 18, 61, Clr)
    LOCATE 19, 47
    MQPrint CHR$(179) + "       (Alt F10 to strip hi bit)" + CHR$(179), LClr
    LOCATE 20, 47
    MQPrint CHR$(179) + " Enter - Toggle SELECTION       " + CHR$(179), LClr
    CALL MPaintBox(20, 49, 20, 53, 112)
    CALL MPaintBox(20, 64, 20, 72, Clr)
    LOCATE 21, 47
    MQPrint CHR$(179) + " Alt M/C - Mark/Clear ALL       " + CHR$(179), LClr
    CALL MPaintBox(21, 49, 21, 51, 112)
    CALL MPaintBox(21, 53, 21, 53, 112)
    CALL MPaintBox(21, 55, 21, 55, 112)
    CALL MPaintBox(21, 70, 21, 72, Clr)
    LOCATE 22, 47
    MQPrint CHR$(179) + " Esc - QUIT Program             " + CHR$(179), LClr
    CALL MPaintBox(22, 49, 22, 51, 112)
    CALL MPaintBox(22, 55, 22, 58, Clr)
    LOCATE 23, 47
    MQPrint CHR$(192) + STRING$(32, 196) + CHR$(217), LClr

END SUB

SUB InitOpts (Rows, SortFlag, FileSpec$, Cnf AS Config) STATIC

SortFlag = 0                            'Directory Sorting Flag
Cmd2$ = Cmd$                            'work with a copy

DO
   Slsh = INSTR(Cmd2$, "/")              'Look for switches
   IF Slsh THEN
      Switch$ = MID$(Cmd2$, Slsh + 1, 1)
      SELECT CASE Switch$
         CASE "H"
           SELECT CASE Cnf.MonTyp
              CASE 7, 11
                 Rows = 50
                 WIDTH , Rows
              CASE 5
                 Rows = 43
                 WIDTH , Rows
              CASE ELSE
           END SELECT
         CASE "N"                       'Sort by Names
            SortFlag = 1
         CASE "E"                       'Sort by Extension
            SortFlag = 2
         CASE "S"                       'Sort by Size
            SortFlag = 3
         CASE "D"                       'Sort by Date
            SortFlag = 4
         CASE ELSE
      END SELECT
      Cmd2$ = MID$(Cmd2$, Slsh + 2)     'Remove `/$' string
      Cmd2$ = LTRIM$(RTRIM$(Cmd2$))     'Remove any spaces
   END IF
LOOP WHILE INSTR(Cmd2$, "/")            'Look for more Switches
  
IF LEN(Cmd2$) = 0 THEN Cmd2$ = "*.*"    'If no File Spec in Command$
                                        '  default to Global search
FileSpec$ = Cmd2$

END SUB

FUNCTION MakeStr$ (Num&) STATIC

    MakeStr$ = LTRIM$(FUsing$(STR$(Num&), "###########,"))

    '--- if linking with P.D.Q. use the following line instead
    'MakeStr$ = LTRIM$(FUsing$(" " + STR$(Num&), "#########,"))

END FUNCTION

SUB Message (Mesg$, Lne, Clr) STATIC

    Msg$ = SPACE$(80)
    Row = CSRLIN
    Col = POS(0)

    LOCATE Lne, 1
    LSET Msg$ = Mesg$
    MQPrint Msg$, Clr
    LOCATE Row, Col

END SUB

FUNCTION ParsPath$ (FileSpec$) STATIC

    Pth = INSTR(FileSpec$, ":")                 'Parse out the File Spec Path
    IF INSTR(FileSpec$, "\") THEN
       FOR Pth = LEN(FileSpec$) TO 1 STEP -1
           IF MID$(FileSpec$, Pth, 1) = "\" THEN EXIT FOR
       NEXT
    END IF
    ParsPath$ = LEFT$(FileSpec$, Pth)

END FUNCTION

SUB PrmTxt (Prompt$, Answer$, AnSize) STATIC

    Row = CSRLIN                        'Save cursor line
    LC = POS(0) + LEN(Prompt$) + 1      'Find Left Column of Answer

    CALL MQPrint(Prompt$ + " ", -1)     'Print the Prompt

    IF LEN(Answer$) < AnSize THEN       'Set the Answer$ to AnSize
       Answer$ = Answer$ + SPACE$(AnSize - LEN(Answer$))
    ELSE
       Answer$ = LEFT$(Answer$, AnSize)
    END IF

                                        'Call Edit Routine
    Editor Answer$, ALen, ScanCode, 0, 0, 112, 112, Row, LC
   
    IF ScanCode = 27 THEN               'See if Escape was pressed
       Answer$ = ""                     'It was, make Answer Nul
       EXIT SUB                         'Bail Out and let the Calling
    END IF                              'routine deal with it

    Answer$ = RTRIM$(LTRIM$(Answer$))   'Strip both sides of answer

END SUB

SUB Sorter (Array$(), DirCnt, Count, SortFlag) STATIC
   
    SELECT CASE SortFlag

       CASE 1           'By Name
          XtnFlag = 0
          SortStrings Array$(), XtnFlag, DirCnt + 1, Count + DirCnt

       CASE 2           'By Extension
          XtnFlag = -1
          SortStrings Array$(), XtnFlag, DirCnt + 1, Count + DirCnt

       CASE 3           'By Size
          REDIM Temp&(DirCnt + Count)
          FOR N = DirCnt + 1 TO Count + DirCnt
              Temp&(N) = QPValL&(MID$(Array$(N), 14))
          NEXT
          SortNum Array$(), Temp&(), DirCnt + 1, Count + DirCnt
          ERASE Temp&

       CASE 4           'By Date
          REDIM Temp&(DirCnt + Count)
          Tme$ = "     :00"                                     'Make a mask
          FOR N = DirCnt + 1 TO Count + DirCnt
              PM& = (MID$(Array$(N), 37, 1) = "p") * -43200
              MID$(Tme$, 1) = MID$(Array$(N), 32, 5)
              IF MID$(Tme$, 1, 2) = "12" THEN
                 IF PM& THEN
                    PM& = 0
                 ELSE
                    MID$(Tme$, 1) = "00"
                 END IF
              END IF
              Min = (Time2Num&(Tme$) + PM&) \ 60
              Temp&(N) = Date2Num%(MID$(Array$(N), 23, 8)) * 1440& + Min
          NEXT
          SortNum Array$(), Temp&(), DirCnt + 1, Count + DirCnt
          ERASE Temp&

       CASE ELSE
    END SELECT
    
END SUB

SUB SortNum (Array$(), Num&(), StrtLst, EndList) STATIC

    S = EndList - StrtLst + 1
    T$ = SPACE$(LEN(Array$(StrtLst)))
    DO
       S = S \ 2
       IF S < 1 THEN EXIT DO
       FOR K = StrtLst TO S + StrtLst - 1
          FOR I = K TO EndList - S STEP S
             J = I
             LSET T$ = Array$(I + S)
             T& = Num&(I + S)
             DO UNTIL T& > Num&(J)
                LSET Array$(J + S) = Array$(J)
                Num&(J + S) = Num&(J)
                J = J - S
                IF J < StrtLst THEN EXIT DO
             LOOP
             LSET Array$(J + S) = T$
             Num&(J + S) = T&
          NEXT I
       NEXT K
    LOOP

END SUB

SUB SortStrings (Array$(), XtnFlag, StrtLst, EndList) STATIC

    S = EndList - StrtLst + 1
    T$ = SPACE$(12)
    Cmp$ = SPACE$(12)
    Tmp$ = SPACE$(LEN(Array$(StrtLst)))
    Blnk$ = SPACE$(3)
    DO
       S = S \ 2
       IF S < 1 THEN EXIT DO
       FOR K = StrtLst TO S + StrtLst - 1
          FOR I = K TO EndList - S STEP S
             J = I
             Ptr = I + S
             IF XtnFlag THEN
                Per = INSTR(Array$(Ptr), ".")
                IF Per THEN
                   LSET T$ = MID$(Array$(Ptr), Per + 1, 3)
                   MID$(T$, 4) = LEFT$(Array$(Ptr), Per - 1)
                ELSE LSET T$ = Blnk$
                   MID$(T$, 4) = Array$(Ptr)
                END IF
             ELSE
                LSET T$ = Array$(Ptr)
             END IF
             LSET Tmp$ = Array$(Ptr)

             DO
                IF XtnFlag THEN
                   Per = INSTR(Array$(J), ".")
                   IF Per THEN
                      LSET Cmp$ = MID$(Array$(J), Per + 1, 3)
                      MID$(Cmp$, 4) = LEFT$(Array$(J), Per - 1)
                   ELSE LSET Cmp$ = Blnk$
                      MID$(Cmp$, 4) = Array$(J)
                   END IF
                ELSE
                   LSET Cmp$ = Array$(J)
                END IF

                IF T$ <= Cmp$ THEN
                   LSET Array$(J + S) = Array$(J)
                   J = J - S
                END IF
             LOOP UNTIL J < StrtLst OR T$ > Cmp$
             LSET Array$(J + S) = Tmp$
          NEXT I
       NEXT K
    LOOP
END SUB

FUNCTION TestDrv (Path$, WriteFlg, Rows) STATIC

    IF INSTR(Path$, ":") THEN
       Drive$ = LEFT$(Path$, INSTR(Path$, ":") - 1)
    ELSE
       Drive$ = ""
    END IF

    Ok = 0
    Ky$ = ""

    DO
        RT = ReadTest(Drive$)
        IF RT THEN
           Ok = -1
        ELSE
           Message "Disk Not Ready!!!   Press [Esc] to Quit, any other key to try again.", Rows, 12
           Ky$ = INPUT$(1)
           Message Crescent$, Rows, 112
        END IF

        IF RT AND WriteFlg THEN
           IF WriteTest(Drive$) THEN
              Ok = -1
           ELSE
              Message "Disk Write Protected!!!   Press [Esc] to Quit, any other key to try again.", Rows, 12
              Ky$ = INPUT$(1)
              Message Crescent$, Rows, 112
              Ok = 0
           END IF
        END IF

    LOOP UNTIL Ok OR Ky$ = CHR$(27)

    TestDrv = Ok
END FUNCTION

