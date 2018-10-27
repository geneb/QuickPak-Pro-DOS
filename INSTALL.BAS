'********** INSTALL.BAS - QuickPak Professional Install Utility

'Copyright (c) 1992 Ethan Winer

'Note: If you run this program in the QB editor the ExeName function will
'return the directory that QB.EXE was run from, which is not necessarily the
'current directory.  In that case you may have to enter the directory name
'where your various .ZIP files reside for INSTALL to find them.
'
'This program was built using QB 4.5 and P.D.Q. with the following commands:
'
'   bc install /o/s;
'   link /nod/noe/packc/far/ex _
'     install _noread _noval _noerror _cprint , , nul , pdq pro;
'   exe2com install
'   del install.exe
'   ren install.com install.exe


DEFINT A-Z

'---- BASIC SUB and FUNCTION procedures in this program file
'
DECLARE SUB Box0 (ULRow, ULCol, LRRow, LRCol, Style, Colr)
DECLARE SUB CDir (DirName$)
DECLARE SUB CopyFile (Source$)
DECLARE SUB DrawScreen ()
DECLARE SUB EditLine (Text$, Row, LeftCol, Length, KeyCode)
DECLARE SUB EarlyEnd ()
DECLARE SUB ErrorEnd (Message$)
DECLARE SUB MakeDir (DirName$)
DECLARE SUB MidCharS (Work$, BYVAL Position, BYVAL NewChar)
DECLARE SUB ReadFile (BYVAL Address)
DECLARE SUB ReadNames (Spec$, Array$())
DECLARE SUB ScrnRest0 (ULRow, ULCol, LRRow, LRCol, SEG Address)
DECLARE SUB ScrnSave0 (ULRow, ULCol, LRRow, LRCol, SEG Address)
DECLARE SUB SelectFiles (FileNames$(), Choice, ExitCode)
DECLARE SUB SetDrive (Drive$)
DECLARE SUB StuffBuf (Work$)

DECLARE FUNCTION DCount% (DirSpec$)
DECLARE FUNCTION DOSError% ()
DECLARE FUNCTION DOSVer% ()
DECLARE FUNCTION ExeName$ ()
DECLARE FUNCTION FCount% (FileSpec$)
DECLARE FUNCTION GetComment$ (FileName$)
DECLARE FUNCTION GetDir$ (Drive$)
DECLARE FUNCTION GetDrive% ()
DECLARE FUNCTION LoadExec% (FileName$, Parameter$)
DECLARE FUNCTION MidChar% (Work$, Position)
DECLARE FUNCTION Prompt% (Which)
DECLARE FUNCTION QPValI% (Work$)
DECLARE FUNCTION SourceDir$ ()


'---- Define some constants and variables, and colors based on display type.
'
DIM SHARED One                          'these save code when used in CALLs
DIM SHARED Temp, Temp$                  'these are reusable scratch variables

CONST MaxFiles% = 19                    'max. number of .ZIP files per disk
CONST DirLength% = 25                   'length of dest. directory display

One = 1                                 'saves four bytes per use in a CALL
PadComment$ = SPACE$(36)                'holds each comment when printing
REDIM DirsMade$(1 TO 100)               'remembers directories we created

Bar$ = "ฬ" + STRING$(78, 205) + "น"     'for the main screen separating bars
Msg$ = SPACE$(79)                       'for messages on the bottom line
IF INSTR(UCASE$(COMMAND$), "/B") THEN MonoFlag = -1   '/b forces mono colors

NormFG = 11: NormBG = 7                 'assume colors for a color display
HiFG = 11: HiBG = 4                     'menu and default directory colors
Hi1 = 75                                'same thing only combined for Box0
MainFG = 10: MainBG = 1                 'main screen and box FG and BG colors
Main1 = 26                              'same thing only combined for Box0
CsrSize = 7                             'color displays use 8 scan lines

DEF SEG = 0                             'see if it's really a color display
MonoMon = (PEEK(&H463) = &HB4)          'if not, MonoMon now equals -1
IF MonoMon OR MonoFlag THEN             'it's monochrome or /b was used
  NormFG = 7: NormBG = 0
  HiFG = 15: HiBG = 0: Hi1 = 15
  MainFG = 0: MainBG = 7: Main1 = 112
  IF MonoMon THEN CsrSize = 12          'mono displays use 13 scan lines
END IF

IF DOSVer% < 300 THEN                   'INSTALL requires DOS 3.0 or later
  PRINT "DOS 3.0 or later required."
  END
END IF

'---- Get the directory INSTALL was run from or prompt for it if needed, to
'     ensure that there's at least one .ZIP file present to install.
'
InstPath$ = SourceDir$
DO
  IF RIGHT$(InstPath$, 1) <> "\" THEN InstPath$ = InstPath$ + "\"
  InstSpec$ = InstPath$ + "*.ZIP"
  NumFiles = FCount%(InstSpec$)
  IF NumFiles THEN EXIT DO
  PRINT "No .ZIP files were found."
  INPUT "Enter the source directory or press Enter to end: ", InstPath$
  IF LEN(InstPath$) = 0 THEN END
LOOP
     
IF MidChar%(InstPath$, 2) <> 58 THEN    'if there's no drive letter (:)
  InstPath$ = CHR$(GetDrive%) + ":" + InstPath$ 'append the current drive
END IF


'---- See if they're installing more than one disk, and if so how many.
'
NumDisks = 1                                'assume only one disk for now
NumDisksFile$ = InstPath$ + "NUMDISKS.*"    'concatenate these just once

IF FCount%(NumDisksFile$) THEN
  DIM NumDisks$(0 TO 1)
  CALL ReadNames(NumDisksFile$, NumDisks$())
  Temp = INSTR(NumDisks$(1), ".")
  NumDisks = QPValI%(MID$(NumDisks$(1), Temp + 1))
END IF


'---- See if there's a DEFAULT.DIR file in the root directory of the first
'     distribution disk, and if so read its contents.  Here we're using
'     FCount to merely see if the file exists.  If there's no DEFAULT.DIR
'     file, default to current drive and directory.  And if the current drive
'     is A or B replace that with C.
'
SaveDir$ = CHR$(GetDrive%) + ":" + GetDir$("")  'save this while we have it
DefaultDir$ = SaveDir$                          'now assign it as the default

Temp = ASC(DefaultDir$)                         'avoid using ASC() twice
IF Temp = 65 OR Temp = 66 THEN                  'don't default to A: or B:
  CALL MidCharS(DefaultDir$, 1, 67)             'if A: or B:, substitute C:
END IF

DefaultDirFile$ = InstPath$ + "DEFAULT.DIR"     'concatenate these just once

IF FCount%(DefaultDirFile$) THEN                'open the file if it exists
  OPEN DefaultDirFile$ FOR INPUT AS #1
  INPUT #1, DefaultDir$                         'read the default directory,
  CLOSE                                         ' trim and capitalize (UCASE$
  DefaultDir$ = UCASE$(RTRIM$(LTRIM$(DefaultDir$))) ' is for cosmetics only)
END IF


'---- See if there's a PROGRAM.RUN file in the root directory of the first
'     distribution disk, and if so read its contents.
'
RunFileName$ = InstPath$ + "PROGRAM.RUN"        'concatenate these just once
IF FCount%(RunFileName$) THEN                   'open the file if it exists
  OPEN RunFileName$ FOR INPUT AS #1
  INPUT #1, RunName$
  CLOSE
  RunName$ = RunName$ + CHR$(13)                'simulate pressing Enter
  IF LEN(RunName$) > 15 THEN RunName$ = ""      'don't use name if too long
END IF


'---- This is the main installation loop that cycles through each diskette.
'
FOR Disk = 1 TO NumDisks

  '---- See how many .ZIP files there are on the current disk, and limit the
  '     number we'll handle to MaxFiles% if there are more than that.  Then
  '     draw/redraw the main screen.
  '
  NumFiles = FCount%(InstSpec$)
  IF NumFiles > MaxFiles% THEN NumFiles = MaxFiles%
 
  CALL DrawScreen
 
  '---- Read the .ZIP file names and display them in a vertical menu.  Then
  '     read any default directories (if present) within each .ZIP file's
  '     comment, and display them in the destination directory fields.  For
  '     each .ZIP file that doesn't have a corresponding default directory
  '     in the comment, use the contents of the main DEFAULT.DIR file found
  '     in the root directory of the disk.
  '
  REDIM ZIPName$(0 TO NumFiles)
  REDIM DestDir$(1 TO NumFiles)
  REDIM Comment$(1 TO NumFiles)

  CALL ReadNames(InstSpec$, ZIPName$())

  FOR X = 1 TO NumFiles                 'look at each .ZIP file comment
    DestDir$(X) = SPACE$(DirLength%)    'create a string to hold the dest dir
    LSET DestDir$(X) = DefaultDir$      'assume none, use the global default
    Comment$(X) = GetComment$(InstPath$ + ZIPName$(X))
    Temp = INSTR(Comment$(X), "þ")      'see if a directory was given
    IF Temp THEN                        'there is a directory for this file
      LSET DestDir$(X) = UCASE$(MID$(Comment$(X), Temp + 1)) 'dir is on right
      Comment$(X) = LEFT$(Comment$(X), Temp - 1)         'and comment on left
    END IF
  NEXT

  FOR X = 1 TO NumFiles                 'add leading blanks to make room
    ZIPName$(X) = "   " + ZIPName$(X)   '  for the CHR$(251) check marks
    IF RIGHT$(Comment$(X), 1) = "๛" THEN    'they want this file checked
      CALL MidCharS(ZIPName$(X), 2, 251)    'so check it in the file list box
      Comment$(X) = LEFT$(Comment$(X), LEN(Comment$(X)) - 1)
    END IF
    LSET PadComment$ = Comment$(X)      'display the directories and comments
    COLOR NormFG, NormBG                'while we're here
    LOCATE X + 4, 2: PRINT DestDir$(X);
    LOCATE X + 4, 44: PRINT PadComment$;
  NEXT

  DO                                    'let the user select the files
    CALL SelectFiles(ZIPName$(), Choice, ExitCode)
    IF ExitCode = 9 THEN                'they pressed Tab
      DO
        CALL EditLine(DestDir$(Choice), Choice + 4, 2, 25, ExitCode)
        SELECT CASE ExitCode            'how did the terminate editing?
          CASE -80                      'Down Arrow
            Choice = Choice + 1         'wrap around if they go past the end
            IF Choice > NumFiles THEN Choice = 1
          CASE -72                      'Up Arrow
            Choice = Choice - 1         'wrap to the end if they go before 1
            IF Choice < 1 THEN Choice = NumFiles
          CASE 27                       'Escape
            CALL EarlyEnd
          CASE -60                      'F2
            ExitCode = -60              'tell SelectFiles to come right back
            EXIT DO                     '  so we can exit both levels of DO
          CASE ELSE
            EXIT DO                     'anything else returns to SelectFiles
        END SELECT
      LOOP
    ELSEIF ExitCode = -60 THEN          'F2
      ExitCode = 0                      'prevent unwanted recursion across
      EXIT DO                           '  multiple disks
    ELSEIF ExitCode = 27 THEN           'Escape
      CALL EarlyEnd
    END IF
  LOOP


  '---- Install the selected files to the specified destination directories.
  '     For each file that is tagged, either change to the appropriate drive
  '     and directory, or ensure that we're back to the original path.
  '
  FOR X = 1 TO NumFiles                       'for each .ZIP file present

    IF MidChar%(ZIPName$(X), 2) = 251 THEN    'if it's tagged to install

      COLOR MainFG, MainBG                    'for the status message below
      CLS
      LSET Msg$ = "Installing" + RTRIM$(MID$(ZIPName$(X), 3)) + "..."
      COLOR HiFG
      PRINT Msg$                              'advise the user as to progress
      COLOR MainFG
     
      DestPath$ = RTRIM$(DestDir$(X))         'work with a copy of the path

      IF MidChar%(DestPath$, 2) = 58 THEN     'if a drive was used (58 = ":")
        CALL SetDrive(DestPath$)              'change to that drive
        IF GetDrive% <> ASC(DestPath$) THEN   'no such drive
          CALL ErrorEnd("Drive " + LEFT$(DestPath$, 2) + " invalid")
        END IF
      ELSE
        CALL SetDrive(DefaultDir$)            'else switch to default drive
      END IF

      'strip off possible trailing "\" unless it refers to the root directory
      IF RIGHT$(DestPath$, 1) = "\" THEN
        Temp = LEN(DestPath$)
        IF Temp > 1 AND RIGHT$(DestPath$, 2) <> ":\" THEN
          DestPath$ = LEFT$(DestPath$, Temp - 1)
        END IF
      END IF

      Temp = -1                               'assume directory now exists
      IF LEN(DestPath$) THEN                  'if a directory name was given

        IF RIGHT$(DestPath$, 1) <> "\" THEN   'and it's not a root directory

          IF DCount%(DestPath$) = 0 THEN      'does the directory exist?
            CALL MakeDir(DestPath$)           'no, so first try to create it
            IF DOSError% THEN
              CALL ErrorEnd("Cannot create " + DestPath$)
            END IF
            Temp = 0                          'it can't possibly have files
            DirsWeMade = DirsWeMade + 1       'show we created another one
            DirsMade$(DirsWeMade) = DestPath$ 'remember its name
          END IF

          FOR Y = 1 TO DirsWeMade             'see of we made this directory
            IF DestPath$ = DirsMade$(Y) THEN  'yes, so there's no need to
              Temp = 0                        '  warn about overwriting files
              EXIT FOR
            END IF
          NEXT

        END IF

        CALL CDir(DestPath$)                  'then try to change to it
        IF DOSError% THEN
          CALL ErrorEnd("Unable to access " + DestPath$)
        END IF

      END IF

      PKCmd$ = "-o "                          'assume they want to be warned
      IF Temp THEN                            'this directory existed
        IF Prompt%(Zero) THEN                 'ask if they want to be warned
          PKCmd$ = ""                         ' to overwrite existing files
        END IF                                ' without further prompting and
      END IF                                  ' use appropriate command if so

      IF NOT PKCopied THEN                    'copy PKUNZIP first time only

        PKCopied = -1                         'flag that we did it already
        CALL CopyFile(InstPath$)              'show where PKUNZIP.EXE is
        PKDir$ = RTRIM$(DestDir$(X))          'remember where we put it!
        IF LEN(PKDir$) = 0 THEN PKDir$ = DefaultDir$ 'use default dir if none
       
        Temp = ASC(RIGHT$(PKDir$, 1))         'check the right-most character
        IF Temp <> 58 AND Temp <> 92 THEN     'if not a colon or backslash
          PKDir2$ = "\"                       ' create a trailing "\"
        END IF                                ' which is appended below

      END IF

      '---- Install all of the files contained in this .ZIP file and check
      '     for an errors returned by either DOS or PKUNZIP. LoadExec returns
      '     positive error values if PKUNZIP was run okay but it returned an
      '     error via the DOS Errorlevel.  If DOS itself reports an error
      '     (perhaps there wasn't enough memory to run the program) LoadExec
      '     returns the DOS error value as a negative number.  Error 8 is the
      '     DOS "Out of memory" error.
      '
      Temp = LoadExec%(PKDir$ + PKDir2$ + "PKUNZIP.EXE", PKCmd$ + InstPath$ + RTRIM$(MID$(ZIPName$(X), 4)))
      IF Temp THEN
        Temp$ = "PKUNZIP reports Error" + STR$(Temp)
        IF Temp < 0 THEN Temp$ = "Out of memory"
        CALL ErrorEnd(Temp$)
      END IF

      IF INKEY$ = CHR$(27) THEN         'allow aborting by pressing Escape
        CALL EarlyEnd
      END IF

    END IF

  NEXT

  IF Disk < NumDisks THEN               'if there are more disks to install
    LOCATE 25, 1                        'prompt to insert the next disk
    COLOR MainFG, MainBG
    LSET Msg$ = " Insert the next disk and press any key when ready"
    PRINT Msg$;
    LOCATE , 52, 1
    DO: LOOP WHILE LEN(INKEY$)          'first clear any pending keys
    DO: LOOP UNTIL LEN(INKEY$)          'then wait for a keypress
    CALL SetDrive(SaveDir$)             'return to the current drive and its
    CALL CDir(SaveDir$)                 '  current directory before going on
  END IF

  Choice = 1                            'force the list to the first item

NEXT Disk


'---- Report success and run the specified program (StuffBuf ignores a null
'     string argument.
'
COLOR 7, 0: CLS
IF PKCopied THEN
  CALL SetDrive(PKDir$)                 'change to the first drive and
  CALL CDir(PKDir$)                     ' directory we installed to
  KILL "PKUNZIP.EXE"                    'delete the copy of PKUNZIP.EXE there
  LOCATE 13, 30: PRINT "Installation complete!"
ELSE
  LOCATE 13, 20: PRINT "No files selected."
END IF

LOCATE 22, 1, 1
CALL StuffBuf(RunName$)                 'stuff the buffer if appropriate
END                                     'and end

SUB CopyFile (Source$) STATIC           'copies PKUNZIP.EXE
 
  Temp$ = Source$ + "PKUNZIP.EXE"
 
  IF FCount%(Temp$) THEN
    OPEN Temp$ FOR BINARY AS #1         'open the input file if it exists
  ELSE                                  'if we can't find it, bag out with
    CALL ErrorEnd("Can't find PKUNZIP.EXE")     ' an error message
  END IF

  OPEN "PKUNZIP.EXE" FOR BINARY AS #2   'now open the target file

  Temp$ = SPACE$(LOF(1))                'make a buffer to hold PKUNZIP.EXE
  GET #1, , Temp$                       'read the source file
  PUT #2, , Temp$                       'write it to the destination
 
  CLOSE                                 'all done here
   
END SUB

SUB DrawBox (ULRow, ULCol, LRRow, LRCol, Style) STATIC
 
  Length = LRCol - ULCol + 1            'calculate this just once
 
  IF Style = 1 THEN
    LineType = 196
    VertBar$ = "ณ"
  ELSE
    LineType = 205
    VertBar$ = "บ"
  END IF

  FOR X = ULRow TO LRRow                'first draw the walls
    LOCATE X, ULCol
    Temp = 32
    IF X = ULRow OR X = LRRow THEN Temp = LineType
    PRINT VertBar$; STRING$(Length - 2, Temp); VertBar$;
  NEXT

  IF Style = 1 THEN                     'then draw the corners
    LOCATE ULRow, ULCol: PRINT "ฺ";
    LOCATE ULRow, LRCol: PRINT "ฟ";
    LOCATE LRRow, ULCol: PRINT "ภ";
    LOCATE LRRow, LRCol: PRINT "ู";
  ELSE
    LOCATE ULRow, ULCol: PRINT "ษ";
    LOCATE ULRow, LRCol: PRINT "ป";
    LOCATE LRRow, ULCol: PRINT "ศ";
    LOCATE LRRow, LRCol: PRINT "ผ";
  END IF

END SUB

SUB DrawScreen STATIC

  SHARED MainFG, MainBG, Main1, Bar$
 
  '---- Draw the title screen and surrounding boxes.
  '
  COLOR MainFG, MainBG: CLS : LOCATE , , 0
  CALL Box0(One, One, 24, 80, 2, Main1)
  LOCATE 2, 23: PRINT "Crescent Software INSTALL Version 1.00"
  LOCATE 3, 1: PRINT Bar$
 
  CALL Box0(3, 27, 24, 43, One, Main1)
  LOCATE 3, 27:  PRINT "ัอออออออออออออออั";
  LOCATE 24, 27: PRINT "ฯอออออออออออออออฯ";
 
  LOCATE 4, 3: PRINT "Destination Directories";
  LOCATE , 31: PRINT "ZIP Files";
  LOCATE , 58: PRINT "Comments"

  LOCATE 25, 1
  PRINT " Up/Down/Space: Select files    Tab: Edit destination    F2: Begin    Esc: Quit";

END SUB

SUB EarlyEnd STATIC

  IF Prompt%(One) THEN
    COLOR 7, 0
    CLS
    LOCATE 24, , 1
    END
  END IF
  LOCATE , , 0

END SUB

SUB EditLine (Text$, Row, LeftCol, Length, KeyCode) STATIC

  SHARED HiFG, HiBG, Hi1, NormFG, NormBG, MonoMon, CsrSize

  '----- Work with a temporary copy.
  Edit$ = SPACE$(Length)
  LSET Edit$ = Text$

  '----- See where to begin editing and print the string.
  TxtPos = 1
  LOCATE Row, LeftCol, 1, CsrSize - 1, CsrSize
  COLOR HiFG, HiBG
  PRINT Edit$;

  '----- This is the main loop for handling key presses.
  DO
     LOCATE , LeftCol + TxtPos - 1, 1

     DO
       Ky$ = UCASE$(INKEY$)
     LOOP UNTIL LEN(Ky$)        'wait for a keypress

     IF LEN(Ky$) = 1 THEN       'create a key code
       KeyCode = ASC(Ky$)       'regular character key
     ELSE                       'extended key
       KeyCode = -ASC(RIGHT$(Ky$, 1))
     END IF

     '----- Branch according to the key pressed.
     SELECT CASE KeyCode

       '----- Backspace: decrement the pointer and the
       '      cursor, and ignore if in the first column.
       CASE 8
         TxtPos = TxtPos - 1
         IF TxtPos < 1 THEN TxtPos = 1
         LOCATE , LeftCol + TxtPos - 1, 0
         IF TxtPos > 0 THEN
           IF InsStatus THEN
             MID$(Edit$, TxtPos) = MID$(Edit$, TxtPos + 1) + " "
           ELSE
             MID$(Edit$, TxtPos) = " "
           END IF
           PRINT MID$(Edit$, TxtPos);
         END IF

       '----- Enter or Escape: this block is optional in
       '      case you want to handle these separately.
       CASE 13, 27
         EXIT DO                'exit the subprogram

       '----- Letter keys: turn off the cursor to hide
       '      the printing, handle Insert mode as needed.
       CASE 32 TO 254
         LOCATE , , 0
         IF InsStatus THEN      'expand the string
           MID$(Edit$, TxtPos) = Ky$ + MID$(Edit$, TxtPos)
           PRINT MID$(Edit$, TxtPos);
         ELSE                   'else insert character
           MID$(Edit$, TxtPos) = Ky$
           PRINT Ky$;
         END IF
         TxtPos = TxtPos + 1    'update position counter
         IF TxtPos > Length THEN TxtPos = Length

       '----- Left arrow: decrement the position counter.
       CASE -75
         TxtPos = TxtPos - 1
         IF TxtPos < 1 THEN TxtPos = 1

       '----- Right arrow: increment position counter.
       CASE -77
         TxtPos = TxtPos + 1
         IF TxtPos > Length THEN TxtPos = Length

       '----- Home: jump to the first character position.
       CASE -71
         TxtPos = 1

       '----- End: search for the last non-blank, and
       '      make that the current editing position.
       CASE -79
         FOR N = Length TO 1 STEP -1
           IF MID$(Edit$, N, 1) <> " " THEN EXIT FOR
         NEXT
         TxtPos = N + 1
         IF TxtPos > Length THEN TxtPos = Length

       '----- Insert key: toggle the Insert state and
       '      adjust the cursor size.
       CASE -82
         InsStatus = NOT InsStatus
         IF InsStatus THEN
           LOCATE , , , CsrSize \ 2, CsrSize
         ELSE
           LOCATE , , , CsrSize - 1, CsrSize
         END IF

       '----- Delete: delete the current character and
       '      reprint what remains in the string.
       CASE -83
         MID$(Edit$, TxtPos) = MID$(Edit$, TxtPos + 1) + " "
         LOCATE , , 0
         PRINT MID$(Edit$, TxtPos);

       '---- All other keys: exit the subprogram
       CASE ELSE
         EXIT DO
     END SELECT

  '----- Loop until the cursor moves out of the field.
  LOOP

  LSET Edit$ = LTRIM$(Edit$)    'trim and reprint the text in the normal
  LOCATE , 2                    ' color before returning
  COLOR NormFG, NormBG
  PRINT Edit$

  Text$ = RTRIM$(Edit$)         'now trim what's on the right too
 
END SUB

SUB ErrorEnd (Message$) STATIC

  COLOR 7, 0
  CLS
  LOCATE 13, 34 - LEN(Message$) \ 2, 1
  PRINT "Error: "; Message$; ", ending."
  END

END SUB

FUNCTION GetComment$ (Zip$) STATIC      'read comment from file named in Zip$

  ZipID$ = "PK" + CHR$(5) + CHR$(6)     'this identifies a file as a ZIP file
 
  OPEN RTRIM$(Zip$) FOR BINARY AS #1    'open the .ZIP file
  FileSize& = LOF(1)                    'get and save its length
  BufferSize = 3072                     'the default header size
  IF BufferSize > FileSize& THEN BufferSize = FileSize&
  Temp$ = SPACE$(BufferSize)            'make buffer to receive ZIP header

  GET #1, FileSize& - BufferSize + 1, Temp$
  CLOSE

  Temp = 0                              'find the last occurrence of PK ID
  DO
     HeaderOffset = Temp                'remember where this one is
     Temp = INSTR(Temp + 1, Temp$, ZipID$)      'find the next one
  LOOP WHILE Temp                               'until no more

  IF HeaderOffset THEN                  'if there's a comment, extract it
    CommentLen = CVI(MID$(Temp$, HeaderOffset + 20, 2))
    GetComment$ = MID$(Temp$, HeaderOffset + 22, CommentLen)
  END IF

  Temp$ = ""                            'free up the memory

END FUNCTION

FUNCTION Prompt% (Which) STATIC

  SHARED HiFG, HiBG, Hi1, MonoMon, CsrSize, DestPath$

  REDIM ScrnArray(1 TO 270)             'this saves the underlying screen
  CALL ScrnSave0(11, 14, 15, 67, SEG ScrnArray(1))

  COLOR HiFG, HiBG
  CALL Box0(11, 15, 14, 67, One, Hi1)   'draw the surrounding box
  IF Which THEN                         'we were called from EarlyEnd
    LOCATE 12, 16                       'show this directory name and prompt
    PRINT "                Are you sure you want              ";
    LOCATE 13, 16, 1, CsrSize - 1, CsrSize
    PRINT "              to quit installing? (Y/N)            ";
    LOCATE , 56
  ELSE                                  'prompt if okay to overwrite files
    LOCATE 12, 16                       'show this directory name and prompt
    PRINT " Installing to "; DestPath$; SPC(67 - POS(0));
    LOCATE 13, 16, 1, CsrSize - 1, CsrSize
    PRINT " Prompt before overwriting existing files? (Y/N)   ";
    LOCATE , 65
  END IF
  DO                                    'wait for Yes or No (only)
    Temp$ = UCASE$(INKEY$)
  LOOP UNTIL INSTR(" YN", Temp$) > 1
  Prompt% = 0                           'assume the answer is No
  IF Temp$ = "Y" THEN Prompt% = -1      'they answered Yes

  CALL ScrnRest0(11, 14, 15, 67, SEG ScrnArray(1))
  ERASE ScrnArray                       'restore screen and reclaim memory
  LOCATE 2                              'put cursor at the top of the screen

END FUNCTION

SUB ReadNames (Spec$, Array$()) STATIC  'reads file names into an array

  FOR X = 1 TO UBOUND(Array$)
    Array$(X) = SPACE$(12)              'create the string to hold the name
  NEXT
  Array$(0) = Spec$                     'the file spec goes in element zero
  CALL ReadFile(BYVAL VARPTR(Array$(0)))  'read the names

END SUB

SUB SelectFiles (FileNames$(), Choice, ExitCode) STATIC

  SHARED NumFiles, NormFG, NormBG, HiFG, HiBG

  IF ExitCode = -60 THEN EXIT SUB       'got here via F2 pressed in EditLine

  COLOR NormFG, NormBG                  'first display all of the choices
  FOR Temp = 1 TO NumFiles
    LOCATE 4 + Temp, 28, 0              'and turn off the cursor
    PRINT FileNames$(Temp);
  NEXT

  IF Choice = 0 THEN Choice = 1         'start at element 1 if first time
  IF Choice > UBOUND(FileNames$) THEN Choice = 1 'or if Choice is too high

  DO
    LOCATE 4 + Choice, 28               'redraw current choice highlighted
    COLOR HiFG, HiBG
    PRINT FileNames$(Choice);
    DO
      KeyHit$ = INKEY$                  'see what they want to do
    LOOP UNTIL LEN(KeyHit$)             'wait for a keypress
   
    IF LEN(KeyHit$) = 1 THEN            'set ExitCode based on the type of
      ExitCode = ASC(KeyHit$)            'key (extended or not) they pressed
    ELSE
      ExitCode = -ASC(MID$(KeyHit$, 2))
    END IF
   
    IF ExitCode = 32 THEN               'spacebar
      IF MidChar%(FileNames$(Choice), 2) = 251 THEN 'if it's now checked
        Temp = 32                       'remove the check mark
      ELSE
        Temp = 251                       'else add a check mark
      END IF
      CALL MidCharS(FileNames$(Choice), 2, Temp)
      ExitCode = -80                    'select the next file automatically
    END IF

    SELECT CASE ExitCode
      CASE -80                          'Down Arrow
        GOSUB Deselect
        Choice = Choice + 1
        IF Choice > NumFiles THEN Choice = 1
      CASE -79                          'End key
        GOSUB Deselect
        Choice = NumFiles
      CASE -72                          'Up Arrow
        GOSUB Deselect
        Choice = Choice - 1
        IF Choice = 0 THEN Choice = NumFiles
      CASE -71                          'Home
        GOSUB Deselect
        Choice = 1
      CASE -60                          'F2
        EXIT SUB
      CASE 27                           'Escape
        EXIT SUB
      CASE 9                            'Tab
        LOCATE Choice + 4, 33
        GOSUB Deselect
        EXIT SUB
      CASE ELSE                         'this is needed for QB 4.0 only
    END SELECT
  LOOP

Deselect:                               're-paint the current choice, so it
  LOCATE Choice + 4, 28                 '  won't appear active
  COLOR NormFG, NormBG
  PRINT FileNames$(Choice);
  RETURN

END SUB

FUNCTION SourceDir$ STATIC

  Temp$ = ExeName$                  'get the directory we're running from

  FOR X = LEN(Temp$) TO 1 STEP -1   'isolate the drive letter and path
    Temp = MidChar%(Temp$, X)       '  (strip off the name INSTALL.EXE)
    IF Temp = 58 OR Temp = 92 THEN  'look for a colon or a backslash
      SourceDir$ = LEFT$(Temp$, X)  'by searching for ":" or "\" this will
      EXIT FOR                      ' work even if the program is renamed
    END IF
  NEXT

END FUNCTION

