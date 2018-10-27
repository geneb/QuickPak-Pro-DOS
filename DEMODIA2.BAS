'******* DEMODI2.BAS - demonstates file selection with DIALOG.BAS         6/91

'Copyright (c) 1991 Crescent Software
'Written by Phil Cramer


DEFINT A-Z
DECLARE SUB Dialog (Choice, Text$(), Response$(), Menu$(), ScrnRow, Style, Clr, Action)

'****************************** IMPORTANT! **********************************
'
' This routine now uses the assembler routine KeyDown to make sure
' that the user has released a terminating key before the Dialog box
' clears itself.  Be sure to see DEMODIAP.BAS for important additional
' information if you are using the QBX editor that comes with BASIC 7.

'*****************************************************************************
'* You may enter a file specification with or without wildcards in this demo.*
'* If wildcards are used, the menu, path and file name will be updated to    *
'* reflect the new file specification. If no wild cards are used and no drive*
'* or path information is given, or a file is selected from the menu, the    *
'* filename will be added to the file spec shown below the "File name" field *
'* when Enter or OK is selected.                                             *
'*****************************************************************************

'---- .ASM Functions
DECLARE FUNCTION Exist% (FileName$)
DECLARE FUNCTION FCount% (FSpec$)
DECLARE FUNCTION GetDir$ (Drive$)
DECLARE FUNCTION GetDrive% ()
DECLARE FUNCTION GoodDrive% (Drive$)
DECLARE FUNCTION QPTrim$ (Work$)
DECLARE FUNCTION DOSError% ()

'---- .ASM Subs
DECLARE SUB DeinstallKeyDown ()
DECLARE SUB CDir (NewDir$)
DECLARE SUB InitMouse (There)
DECLARE SUB SetDrive (Drive$)

COLOR 1, 0
CLS

CALL InitMouse(There)                  'Initialize the mouse driver
LOCATE 1, 1: PRINT STRING$(2000, 176); 'Draw an attractive background
FileName$ = "*.*"                      'Start with all files in default dir
Drive$ = CHR$(GetDrive)                'Save the current drive
Path$ = GetDir$(Drive$)                'Save the current path

OrigDrv$ = Drive$                      'Save a copy so we can restore it later
OrigPath$ = Path$                      'Ditto

FPath$ = Drive$ + ":" + Path$          'Build the file spec
Count = FCount%(FileName$)                'See how many files match the spec
IF Count = 0 THEN Count = 1            'Make sure to dim at least 1 element
REDIM Menu$(Count)
FOR i = 1 TO Count                     'Set each element to 12 spaces long
  Menu$(i) = SPACE$(12)
NEXT
Menu$(0) = FileName$                   'Place spec in element 0
CALL ReadFile(BYVAL VARPTR(Menu$(0)))  'Load the Menu$() with files
CALL SortStr(BYVAL VARPTR(Menu$(1)), Count, 0)


REDIM Text$(11)                        'Set up the Dialog box
REDIM Response$(11)
Text$(0) = " Load File "               'Dialog box Title
Text$(1) = "< OK >"                    'Command button
Text$(2) = "< Cancel >"                'Ditto
Text$(3) = " "                         'Blank line
Text$(4) = "{30} File Name"            'Text entry field, 30 characters long
Text$(5) = "|208| Files"               'Menu field, 2 columns, 8 rows
Text$(6) = SPACE$(30)                  'Plain text field, 30 characters long
LSET Text$(6) = FPath$                 'Place the current path in Text$(6)
Text$(7) = " "                         'Blank line
Text$(8) = " Load file as:            "'Left justify Plain text
Text$(9) = "( ) Module"                'Option button
Text$(10) = "( ) Include"              'Ditto
Text$(11) = "( ) Document"             'Ditto

Response$(4) = FileName$               'Place current file name Response$(4)
Response$(9) = CHR$(7)                 'Must assign a "dot" to an option field

Style = 1                              'Single line border
Clr = 112                              'Black text, white background
Action = 1                             'Start Dialog in Polled Mode

DO
  CALL Dialog(Choice, Text$(), Response$(), Menu$(), ScrnRow, Style, Clr, Action)

  TSpec$ = QPTrim$(Response$(4))      'Trim off any blanks before we test
                                      'If they have selected a new menu choice
  IF LEN(Response$(5)) AND Response$(5) <> LastMenu$ THEN
    LSET Response$(4) = Response$(5)  'Place the Menu choice in the File name
    LastMenu$ = Response$(5)          ' field and remember which one
    IF Action <> 4 THEN Action = 2    'Re-display unless they want to exit
  END IF

  IF Action = 4 AND Choice <> -1 THEN     'Enter or < OK >
                                          'Look for wild cards in the spec
    IF INSTR(TSpec$, "?") OR INSTR(TSpec$, "*") OR LEFT$(TSpec$, 2) = ".." THEN

      DriveThere = 0                      'Reset flags
      PathInfo = 0
      PathFound = 0
      Start = 1                           'Default starting point for PathInfo

      IF TSpec$ = ".." THEN
        TPath$ = TSpec$                   'Make the path$ ".."
        TFileName$ = FileName$            'Use the last filename
        PathInfo = -1                     'Set flags
        PathFound = -1
      END IF

      '---- Look for drive info
      IF MID$(TSpec$, 2, 1) = ":" THEN         'See if a drive is in the path
        DriveThere = -1
        IF GoodDrive%(LEFT$(TSpec$, 1)) THEN    'If its a valid drive,
          TDrive$ = UCASE$(LEFT$(TSpec$, 1))   ' assign Drive$
          Start = 3                            'Search for path starting at 3
        ELSE                                   'Bad drive, restore previous
          LSET Text$(6) = Drive$ + ":" + Path$ 'path and file name
          LSET Response$(4) = FileName$
          Action = 2                           'Action 2 forces re-display
          GOTO BadSpec                         'Hopeless, bail out
        END IF
      END IF

      IF NOT DriveThere THEN                   'If Spec$ does not include
        TDrive$ = Drive$                       ' a drive, use last drive
      END IF

      '---- Look for path info
      IF NOT PathFound THEN
        IF INSTR(TSpec$, "\") THEN               'Contains path information
          PathInfo = -1
          FOR i = LEN(TSpec$) TO 1 STEP -1       'Find where it ends
            IF MID$(TSpec$, i, 1) = "\" THEN     ' and determine path$
              TPath$ = UCASE$(MID$(TSpec$, Start, i - Start))
              IF TPath$ = "" THEN TPath$ = "\"
              TFileName$ = UCASE$(RIGHT$(TSpec$, LEN(TSpec$) - i))
              EXIT FOR
            END IF
          NEXT
        ELSE                                     'Must just be a file name
          TFileName$ = UCASE$(RIGHT$(TSpec$, LEN(TSpec$) - Start + 1))
        END IF
      END IF
      IF NOT PathInfo THEN TPath$ = Path$        'If no path specified then
                                                 ' use last path
      '---- See if they have made a selection from the menu
      IF Response$(5) <> "" THEN                 'If a menu item is active
        LSET Response$(4) = Response$(5)         ' change the file spec
        TFileName$ = QPTrim$(Response$(5))
        IF Path$ = "\" THEN Path$ = ""
        Temp$ = Drive$ + ":" + Path$ + "\" + TFileName$
        Response$(4) = Temp$
        EXIT DO                                  'and bail out
      END IF

      CALL SetDrive(TDrive$)
      CALL CDir(TPath$)
      IF DOSError% THEN                          'Must be a bad path
        LSET Response$(4) = FileName$
        Action = 2
        BEEP
        GOTO BadSpec
      ELSE
        IF Exist%(TFileName$) THEN
          Drive$ = TDrive$
          Path$ = GetDir$(Drive$)                'Save the current path
          FileName$ = TFileName$
          LSET Response$(4) = FileName$
          LSET Text$(6) = Drive$ + ":" + Path$
          Count = FCount%(TFileName$)            'Load the Menu$()
          IF Count = 0 THEN Count = 1            ' with files from
          REDIM Menu$(Count)                     ' the new file spec
          FOR i = 1 TO Count
            Menu$(i) = SPACE$(12)
          NEXT
          Menu$(0) = TFileName$
          CALL ReadFile(BYVAL VARPTR(Menu$(0)))
          CALL SortStr(BYVAL VARPTR(Menu$(0)), Count, 0)
          IF Count > 1 THEN CALL SortStr(BYVAL VARPTR(Menu$(1)), Count, 0)
          Action = 2
        ELSE
          LSET Response$(4) = FileName$
          Action = 2
        END IF
      END IF
    ELSE

      '---- No wildcards, must be complete file spec
      IF INSTR(TSpec$, ":") = 0 THEN             'if there is no drive info,
        TPath$ = Drive$ + ":"                    ' use the last drive
      END IF
      IF INSTR(TSpec$, "\") = 0 THEN             'If there is no path info,
        IF Path$ = "\" THEN Path$ = ""
        TPath$ = TPath$ + Path$ + "\"            ' use the last path
      END IF
      Response$(4) = TPath$ + QPTrim$(Response$(4)) 'Assign complete path
      EXIT DO                                       'and bail out
    END IF
  END IF

  Response$(5) = ""

BadSpec:
LOOP UNTIL Choice = -1

Action = 5                               'Action 5 clears the Dialog box
CALL Dialog(Choice, Text$(), Response$(), Menu$(), ScrnRow, Style, Clr, Action)

COLOR 15
LOCATE 1, 1: PRINT "You picked: "; Response$(4);

IF Exist%(QPTrim$(Response$(4))) AND Choice <> -1 THEN 'If it's a valid path
  'Code to load the file goes here
  'SELECT CASE VAL(Response$(8))
  '  CASE 1                              'Load as Module
  '  CASE 2                              'Load as Include
  '  CASE 3                              'Load as Document
  'END SELECT
ELSE                                     'If the file spec is invalid
  REDIM Text$(5)                         ' give them a message
  REDIM Response$(0)
  REDIM Menu$(0)
  Text$(1) = "< OK >"
  Text$(2) = "< Help >"
  Text$(3) = " "
  Text$(4) = "   File not found   "
  Text$(5) = " "
  Choice = 1
  Action = 0
  CALL Dialog(Choice, Text$(), Response$(), Menu$(), ScrnRow, Style, Clr, Action)
END IF

CALL DeinstallKeyDown                    'Remove KeyDown routine
CALL SetDrive(OrigDrv$)                  'Restore original drive
CALL CDir(OrigPath$)                     'Restore original path

END                                      'Fini

