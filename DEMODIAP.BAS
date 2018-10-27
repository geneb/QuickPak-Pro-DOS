'******** DEMODIAP.BAS -- shows the DIALOG.BAS routine in re-entrant mode 6/91

'Copyright (c) 1990 Crescent Software
'written by Phil Cramer

'******************************* IMPORTANT!*********************************
'
' This routine now uses the assembler routine KeyDown to make sure
' that the user has released a terminating key before the Dialog box
' clears itself.  This allows you to call consecutive Dialog boxes
' or other routines that poll for the same keys, without falling
' through them prematurely.  If you are using QBX, it is important to
' call DeinstallKeyDown before your program ends, otherwise your PC
' may appear to be hung. If you press Ctrl-Break to get out of either
' this demo or your own program that uses KeyDown while in the QBX
' environment, your computer may also appear to be hung.  However, you
' can re-start it by using a mouse and selecting RUN and START from the
' QBX pulldown menu.  Calling DeinstallKeyDown is not required when
' using QuickBASIC.
'
'****************************************************************************

DEFINT A-Z
DECLARE SUB DeinstallKeyDown ()
DECLARE SUB Dialog (Choice, Text$(), Response$(), Menu$(), ScRow, Style, Clr, Action)
DECLARE SUB DisplayInfo (Row, Choice, Response$())

COLOR 1, 0
CLS

PRINT STRING$(2000, 176);

CALL InitMouse(There)            'Test for and initialize the mouse
CALL ShowCursor

'-----Set up headings for re-entrant info
CALL QPrintRC(SPACE$(80), 2, 1, 30)
CALL QPrintRC("Text field #1:   ", 1, 1, 30)
CALL QPrintRC("Text field #2:   ", 1, 18, 30)
CALL QPrintRC("Check box:  ", 1, 35, 30)
CALL QPrintRC("Option #1:  ", 1, 47, 30)
CALL QPrintRC("Option #2:  ", 1, 59, 30)
CALL QPrintRC("Menu item:", 1, 71, 30)

CALL SetCursor(1, 1)                         'Home the mouse cursor

REDIM Text$(13)                              'Dim arrays for Dialog box
REDIM Response$(13)
REDIM Menu$(11)
RESTORE Here1
FOR i = 1 TO 11                              'Read data for Menu/List box
  READ Menu$(i)
NEXT

Text$(0) = " Re-entrant Dialog Box "         'Dialog box title
Text$(1) = "< OK >"                          'Command button
Text$(2) = "< CANCEL >"                      'Command button
Text$(3) = "< HELP >"                        'Command button
Text$(4) = " "                               'Blank line
Text$(5) = "{16} Text field #1"              'Text entry field, 16 characters
Text$(6) = "{16} Text field #2"              'Text entry field, 16 characters
Text$(7) = " "                               'Blank Line
Text$(8) = "[ ] Check box"                   'Check box
Text$(9) = " "                               'Blank line
Text$(10) = "( ) Option #1"                  'Option button
Text$(11) = "( ) Option #2"                  'Option button
Text$(12) = " "                              'Blank line
Text$(13) = "|8| List box"                   'Menu/List field, 1 column, at
                                             ' least 8 rows
Response$(5) = "Some text"                   'Text to appear in Text field #1
Response$(6) = "More text"                   'Text to appear in Text field #2
Response$(10) = CHR$(7)                      'Assign a dot to Option button #1

Style = 12                                   'Double line all around, w/shadow
Clr = 112                                    'Black on white
Action = 1                                   'Value for re-entrant mode
Choice = 1                                   'Must initialize Choice to 1

DO
  CALL Dialog(Choice, Text$(), Response$(), Menu$(), ScRow, Style, Clr, Action)

  'Display the re-entrant Response$() data
  CALL QPrintRC(Response$(5), 2, 1, 31)      'Text field #1
  CALL QPrintRC(Response$(6), 2, 18, 31)     'Text field #2
                                            
  IF Response$(8) = "" THEN                  'Check box
    CALL QPrintRC(" ", 2, 35, 31)
  ELSE
    CALL QPrintRC(Response$(8), 2, 35, 31)
  END IF

  IF Response$(10) = "" THEN                 'Option button #1
    CALL QPrintRC(" ", 2, 47, 31)
  ELSE
    CALL QPrintRC(Response$(10), 2, 47, 31)
  END IF

  IF Response$(11) = "" THEN                 'Option button #2
    CALL QPrintRC(" ", 2, 59, 31)
  ELSE
    CALL QPrintRC(Response$(11), 2, 59, 31)
  END IF

  CALL QPrintRC(Response$(13), 2, 70, 31)    'Menu choice


   'Determine which terminating key was pressed
  SELECT CASE Choice
    CASE 1, 101         'OK, Enter or Mouse double-clicked in menu field
      IF Action = 4 THEN Action = 5

    CASE -1, 2           'Cancel or Escape
      IF Action = 4 THEN Action = 5

    CASE 3              'Help
      IF Action = 4 THEN Action = 5

    CASE ELSE
  END SELECT

IF Action = 5 THEN    'Action 5 clears the Dialog box
  CALL Dialog(Choice, Text$(), Response$(), Menu$(), ScRow, Style, Clr, Action)
END IF

LOOP UNTIL Action = 0
CALL DeinstallKeyDown      'Uninstall the routine that checks for keys down
                           '(Mandatory for QBX, not req'd for QuickBASIC)

CALL QPrintRC(SPACE$(80), 23, 1, 30)      'Clear bottom 3 rows to blue
CALL QPrintRC(SPACE$(80), 24, 1, 30)
CALL QPrintRC(SPACE$(80), 25, 1, 30)
CALL DisplayInfo(25, Choice, Response$()) 'Display data returned by Dialog

DO
  Ky$ = INKEY$
LOOP UNTIL Ky$ <> ""

Here1:
DATA " Item 1  ",  " Item 2  ",  " Item 3  ",  " Item 4  "
DATA " Item 5  ",  " Item 6  ",  " Item 7  ",  " Item 8  "
DATA " Item 9  ",  " Item 10 ",  " Item 11 "

SUB DisplayInfo (Row, Choice, Response$())

  LOCATE Row - 2, 1
  CALL QPrint0("Data returned from previous Dialog box:", 30)
  LOCATE Row - 1, 1
  ClearString$ = SPACE$(80)
  CALL QPrint0(ClearString$, 31)
  LOCATE Row, 1
  CALL QPrint0(ClearString$, 31)

  LOCATE Row - 1, 1
  CALL QPrint0("Active Button= ", 31)
  LOCATE Row - 1, 15
  CALL QPrint0(STR$(Choice), 31)

  FOR i = 1 TO UBOUND(Response$, 1)
    IF INSTR(Response$(i), "<") THEN
      Response$ = ""
    ELSE
      Response$ = Response$ + LTRIM$(RTRIM$(Response$(i))) + "  "
    END IF
  NEXT

  LOCATE Row, 1
  CALL QPrint0(LTRIM$(Response$), 31)

END SUB

