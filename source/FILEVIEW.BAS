'***** FILEVIEW.BAS - demonstrates the FileView file browser

'Copyright (c) 1990 Crescent Software, Inc.
'written by Paul Passarelli 4 May 1990
'revised 10 Aug 1990
'

DEFINT A-Z

DECLARE SUB FileView (FileName$, Ky, Action, FVI AS ANY, SEG Array)
DECLARE SUB Editor (Work$, ActiveLen, KeyCode, NumOnly, DoCaps, NColor, EColor, Row, Col)

DECLARE FUNCTION DosError%
DECLARE FUNCTION WhichError%
DECLARE FUNCTION ErrorMsg$ (ErrNo%)
DECLARE SUB SetError (ErrNo%)

TYPE FVInfo
    Colr        AS INTEGER      'Text color (white on black default)
    ULRow       AS INTEGER      'these four describe the window's corners
    ULCol       AS INTEGER
    LRRow       AS INTEGER
    LRCol       AS INTEGER
    HorizOffset AS INTEGER      'left margin within the window (see below)
    LoPtr       AS INTEGER      'used internally -- do not change!
    FileHandle  AS INTEGER      'internal (the DOS file handle if you care)
    EndOfFile   AS INTEGER      'used internally -- do not change!
    LineNumber  AS LONG         'line number of top line displayed, READ ONLY
    TabStop     AS INTEGER      'Tab stop setting (see below)
    FileSeek    AS LONG         'force read anywhere in the file (see below)
    FileOffset  AS LONG         'used internally -- do not change!
END TYPE

'------ description of each component in the TYPE definition above:
'
'   Colr specifies the combined foreground/background color
'
'   ULRow, ULCol, LRRow, and LRCol describe the window boundaries
'
'   HorizOffset:
'     Used to specify the left margin within the window (in columns).
'     It is used internally by FileView, but you may also assign it to force
'     the screen to be shifted right by specifying a positive number.
'
'   FileSeek:
'     When FileView is being used in the polled mode (and after it has been
'     called at least once), you may assign FileSeek to any byte offset
'     within the file.  FileView will then display the line in which that
'     offset occurs at the top of the screen.
'
'   TabStop:
'     This sets the width (number of columns) for Tab stops.  The normal
'     value is 8, which means Tab to the next column that is a multiple of
'     8 characters.  Leave this set to 0 to not expand Tab characters, and
'     instead display the Tab character itself.


  DIM FVI0 AS FVInfo            'create the TYPE variable
  DIM Array(1 TO 16384)         'set up the MANDATORY 32K buffer
 
  FVI0.Colr = 30                'select a display color
  FVI0.ULRow = 2                'define the window corners
  FVI0.ULCol = 1
  FVI0.LRRow = 24
  FVI0.LRCol = 80
  FVI0.TabStop = 8

  FileName$ = SPACE$(64)                'holds the filename
 
  CLS
  LSET FileName$ = "FILEVIEW.BAS"       'view ourselves
  Ky = 0                                'no keystrokes pending
  Action = 0                            'tell FileView to assume full control

  DO
    IF DosError% THEN
       LOCATE 25, 1
       PRINT ErrorMsg$(WhichError%); SPC(50);
       DO: LOOP UNTIL LEN(INKEY$)
    END IF
 
    LOCATE 25, 1
    PRINT "Press Escape to quit ";
 
    LOCATE 1, 1
    PRINT "File to browse:"
   
    Editor FileName$, ActiveLen, KeyCode, 0, 0, 112, 112, 1, 17
    IF KeyCode = 27 THEN END
 
    LOCATE 25, 1
    PRINT "Use the cursor keys, and then press Escape to continue this demo";
 
    FileView FileName$, Ky, Action, FVI0, Array(1)

  LOOP WHILE DosError%
  'This concludes the simplest file browse demo.
 
 
  CLS
 
  REDIM FVI(1 TO 2) AS FVInfo   'define a TYPE for each window
  REDIM Array2(1 TO 16384)      'this buffer is for the second file

  FVI(1).Colr = 31              'color 1
  FVI(1).ULRow = 2              'window 1
  FVI(1).ULCol = 1
  FVI(1).LRRow = 12
  FVI(1).LRCol = 80
  FVI(1).TabStop = 8

  FVI(2).Colr = 111             'color 2
  FVI(2).ULRow = 14             'window 2
  FVI(2).ULCol = 1
  FVI(2).LRRow = 23
  FVI(2).LRCol = 80
  FVI(2).TabStop = 8

  'Now let's look at the same file again with a twist.
 
  Action = 1            'initialize the polled mode of FileView        
  DO
    LOCATE 1, 1
    PRINT "Upper Window: "
    Editor FileName$, ActiveLen, KeyCode, 0, 0, 112, 112, 1, 15
    IF KeyCode = 27 THEN END
    FileView FileName$, Ky1, Action, FVI(1), Array(1)
    LOCATE 1, 61
    PRINT " Top Line:"; FVI(1).LineNumber;
  LOOP WHILE DosError

 
 
  'initialize a second copy of the polled mode of FileView        
 
  LSET FileName$ = "DECLARE.BAS"        'this is the second file to view
  Action = 1
  DO
    LOCATE 13, 1
    PRINT "Lower Window: "
    Editor FileName$, ActiveLen, KeyCode, 0, 0, 112, 112, 13, 15
    IF KeyCode = 27 THEN END

    FileView FileName$, Ky2, Action, FVI(2), Array2(1)
    LOCATE 13, 61
    PRINT " Top Line:"; FVI(2).LineNumber;
  LOOP WHILE DosError

  LOCATE 24, 1
  PRINT "Use F6 to switch between upper/lower windows, F3 to toggle single/dual.";
  LOCATE 25, 1
  PRINT "Press Tab or Shift-Tab to skip-scroll, or S to seek to a specific offset.";
 
 
  File = 1

  DO
   
    'these first 2 blocks handle each browser when it is called alone
   
    IF (File = 1) AND NOT Both THEN
       FileView FileName1$, Ky1, Action, FVI(1), Array(1)
       LOCATE 1, 70
       PRINT FVI(1).LineNumber; "   ";
       Ky = Ky1
    END IF
 
    IF (File = 2) AND NOT Both THEN
       FileView FileName2$, Ky2, Action, FVI(2), Array2(1)
       LOCATE 13, 70
       PRINT FVI(2).LineNumber; "   ";
       Ky = Ky2
    END IF
   
   
    'this block handles simultaneous operations
   
    IF Both THEN
       KyA = Ky
       KyB = Ky
       ActionA = Action
       ActionB = Action
    
       FileView FileName1$, KyA, ActionA, FVI(1), Array(1)
       LOCATE 1, 70
       PRINT FVI(1).LineNumber; "   ";
       FileView FileName2$, KyB, ActionB, FVI(2), Array2(1)
       LOCATE 13, 70
       PRINT FVI(2).LineNumber; "   ";

       IF KyA = 0 OR KyB = 0 THEN Ky = KyA OR KyB
    
       IF ActionA = 4 OR ActionB = 4 THEN
          Action = 4
       ELSE
          Action = 3
       END IF
    END IF
 
 
    'here we turn the TAB key into an 8 column right shift

    IF Ky = 9 THEN        'tab
       IF Both THEN
          FVI(1).HorizOffset = FVI(1).HorizOffset + 8
          FVI(2).HorizOffset = FVI(2).HorizOffset + 8
       ELSE
          FVI(File).HorizOffset = FVI(File).HorizOffset + 8
       END IF
       Action = 2
    END IF
 
   
    'this complements the TAB block above
   
    IF Ky = -15 THEN      'shift-tab
       IF Both THEN
          FVI(1).HorizOffset = FVI(1).HorizOffset - 8
          IF FVI(1).HorizOffset < 0 THEN FVI(1).HorizOffset = 0
          FVI(2).HorizOffset = FVI(2).HorizOffset - 8
          IF FVI(2).HorizOffset < 0 THEN FVI(2).HorizOffset = 0
       ELSE
          FVI(File).HorizOffset = FVI(File).HorizOffset - 8
          IF FVI(File).HorizOffset < 0 THEN FVI(File).HorizOffset = 0
       END IF
       Action = 2
    END IF
 
 
   
    'look for the "S" key to force a SEEK to some absolute file location
 
    IF Ky AND FileSeek& <> 0 THEN
NoLoc:
       COLOR , 7
       LOCATE 1, 35
       PRINT "                        ";
       LOCATE 13, 35
       PRINT "                        ";
       FileSeek = 0
       COLOR , 0
    END IF
    IF Ky = ASC("S") OR Ky = ASC("s") THEN        'Seek
       FileSeek$ = "       "
       KeyCode = 0
       IF File = 1 THEN
          LOCATE 1, 35
          PRINT "Absolute LOC"
          Editor FileSeek$, ActiveLen, KeyCode, 1, 0, 112, 112, 1, 48
          IF KeyCode = 27 THEN END
       ELSE
          LOCATE 13, 35
          PRINT "Absolute LOC"
          Editor FileSeek$, ActiveLen, KeyCode, 1, 0, 112, 112, 13, 48
          IF KeyCode = 27 THEN END
       END IF
       FileSeek& = VAL(FileSeek$)
       IF FileSeek& = 0 THEN
          Ky = FileSeek&
          GOTO NoLoc
       END IF
       FVI(File).FileSeek = FileSeek&
    END IF
 
   
   
    'the F6 key toggles the active window
    IF Ky = -64 THEN
       IF File = 1 THEN
          File = 2
       ELSE
          File = 1
       END IF
    END IF

  
    'the F3 key toggles 1 or both windows
    IF Ky = -61 THEN Both = NOT Both
 
  LOOP UNTIL Action = 4


  'finally we close each file by using Action = 5

  FileView FileName1$, 0, 5, FVI(1), Array(1)
  FileView FileName2$, 0, 5, FVI(2), Array2(1)

