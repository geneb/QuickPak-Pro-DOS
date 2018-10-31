'********** DEMODIAL.BAS -- shows the DIALOG.BAS routine          6/91         2/91

'Copyright (c) 1990 Crescent Software
'written by Phil Cramer

DEFINT A-Z

'******************************* IMPORTANT!*********************************3
'
' This routine now uses the assembler routine KeyDown to make sure
' that the user has released a terminating key before the Dialog box
' clears itself.  Please see the comments in DEMODIAP.BAS for some
' important information if you are using the QBX editor from BASIC 7.


'****************************************************************************3
'* Calling Syntax:                                                           *
'*                                                                           *
'* CALL Dialog(Choice, Text$(), Response$(), Menu$(), ScrnRow, Style, _      *
'*         Clr, Action)                                                      *
'*                                                                           *
'* Where:                                                                    *
'*       Choice returns the number of the active Command Button. If the      *
'*         Escape key was pressed or < Cancel > was selected, Choice         *
'*         returns -1. If the mouse was double-clicked on a menu item,       *
'*         Choice returns 101.                                               *
'*                                                                           *
'*       Text$() is a string array that indicates the type of data to be     *
'*         displayed, and its related text.  (See "Setting up a Dialog Box"  *
'*         below.)                                                           *
'*                                                                           *
'*       Response$() is a parallel array that on entry passes the text to be *
'*         displayed within the various entry fields, and on exit returns    *
'*         the data entered.  For Option Buttons, the number of the box      *
'*         checked is returned in all of the Option Button elements so that  *
'*         you need only check any one of these elements to find the option  *
'*         that was selected.                                                *
'*                                                                           *
'*       Menu$() is an array of data to be displayed in the menu/list box.   *
'*         The lengths of the strings in the array MUST all be equal.        *
'*                                                                           *
'*       ScrnRow if set to 0 will automatically center the Dialog Box        *
'*         vertically on the screen.  ScrnRow set to -1 will allow you to    *
'*         locate the dialog box at any screen row using LOCATE to specify   *
'*         the upper row before the call.  The dialog box must, of course,   *
'*         fit in the space that you have allowed.                           *
'*                                                                           *
'*       Style is a number from 1-4 that determines what type of line type   *
'*         to use to draw the box and dividing line in the Dialog Box, and   *
'*         corresponds to the number code in the Box routine in QuickPak     *
'*         Professional.  Adding 10 to the line type number causes a drop    *
'*         shadow to be displayed.                                           *
'*                                                                           *
'*       Clr is the desired dialog box color, coded in the format used by    *
'*         QuickPak Professional (see COLORS.BAS).                           *
'*                                                                           *
'*       Action is a unique variable that when set properly, allows the      *
'*         Dialog box to either behave in a re-entrant or non re-entrant     *
'*         manner                                                            *                                                                           *
'*                                                                           *
'*         Action = 0 Dialog is not re-entrant                               *
'*         Action = 1 Initializes Dialog in re-entrant mode, i.e. the        *
'*                    underlying screen is saved, the dialog box is          *
'*                    displayed, Action is set to 3, and through a DO loop   *
'*                    control is passed alternately between the dialog box   *
'*                    and the calling program after each keypress. (Menu     *
'*                    and text data is only returned after exiting those     *
'*                    fields.)                                               *
'*         Action = 2 Updates the data in the dialog box, but without        *
'*                    redrawing the dialog box itself.                       *
'*         Action = 4 When returned from the Dialog sub-routine, indicates   *
'*                    that a terminating key has been pressed.               *
'*         Action = 5 Clears the dialog box and redisplays the underlying    *
'*                    screen.                                                *
'*                                                                           *
'*   To run this demo in either 43 line or 50 line modes, simply change the  *
'*   variable SRows (below) to the appropriate number, and change the CONST  *
'*   VMid in the main module DIALOG.BAS to the number of rows \ 2 + 1        *
'*                                                                           *
'*****************************************************************************

'Basic subs
DECLARE SUB Dialog (Choice, Text$(), Response$(), Menu$(), ScrnRow, Style, Clr, Action)
DECLARE SUB DisplayInfo (SRows, Choice, Response$())

'Asm subs/function
DECLARE SUB ClearScr0 (ULRow, ULCol, LRRow, LRCol, Colr)
DECLARE SUB DeinstallKeyDown ()
DECLARE SUB FillScrn0 (ULRow, ULCol, LRRow, LRCol, Colr, Char)
DECLARE SUB ReadFile (BYVAL Address)
DECLARE FUNCTION FCount% (FSpec$)
DECLARE FUNCTION GetDrive% ()
DECLARE FUNCTION GetDir$ (Drive$)


SRows = 25                     'These indicate the size of the display
SCols = 80
Row = 1                        'The help dialog boxes default to row 1
CLS
CALL InitMouse(There)          'This is mandatory before the mouse is used
CALL SetCursor(1, 1)           'Home the mouse cursor
WIDTH SCols, SRows
CALL FillScrn0(1, 1, SRows, SCols, 1, 176)     'make an attractive background
CALL ClearScr0(SRows - 2, 1, SRows, SCols, 31) 'clear a box at the bottom

Drive$ = CHR$(GetDrive)        'Find the current drive
Directory$ = GetDir$(Drive$)   'Find the current directory
Path$ = Drive$ + ":" + Directory$  'Make it a string
Buff$ = SPACE$(25)             'Allocate memory
LSET Buff$ = Path$

Spec$ = "*.*"                  'Read some files names for the first demo
Count = FCount%(Spec$)         'Count the files
IF Count = 0 THEN
  PRINT "This demo requires you to be in a directory with some files in it!"
  END
END IF

IF Count = 0 THEN Count = 1    'In case there are no matching files
REDIM Menu$(Count)             'Make an array to hold them
FOR i = 1 TO Count             'Allocate space for each name
  Menu$(i) = SPACE$(12)
NEXT

Menu$(0) = Spec$               'Read the names
CALL ReadFile(BYVAL VARPTR(Menu$(0)))

'-----Dialog Box #1
                               '  **** Setting up a Dialog Box ****
REDIM Text$(13)
REDIM Response$(13)
Text$(0) = " Load File "       'Dialog Box title (if any) goes in element 0
Text$(1) = "< OK >"            'Command buttons MUST start at element 1 and
Text$(2) = "< Cancel >"        ' MUST be contiguous. You may have as many
Text$(3) = "< Help >"          ' buttons as will fit on the screen or as few
                               ' as one
Text$(4) = " "                 'Blank line
Text$(5) = "{25} File Name:"   'The {} indicate a text input box. The number
                               ' within the brackets indicate the max length of
                               ' text to be entered. Adding 100 to this number
                               ' will force numbers only to be entered
Text$(6) = "|305| Files:"      'The || indicate a list box. The right two
                               ' digits between these two characters indicate
                               ' the number of menu lines to display, however,
                               ' this number may be overridden if the Dialog
                               ' box-8 height is geater. To display multiple
                               ' columns, add the number of columns * 100.
Text$(7) = Buff$
Text$(8) = " "
Text$(9) = "ÄÄ Load as: ÄÄ        "   'Plain text
Text$(10) = "( ) Module"       'The ( ) indicate option buttons. There may be
Text$(11) = "( ) Include"      ' only one grouping of option buttons, but
Text$(12) = "( ) Document"     ' is no limit to the number of option buttons.
                               ' Option buttons MUST also be consecutive
Text$(13) = " "                'Blank line
Response$(5) = Spec$           'Make "File Name: text box display Spec$
Response$(7) = Text$(7)
Response$(10) = CHR$(7)        'You MUST place a dot in one of the option
                               ' button boxes
Temp$ = Response$(5)           'Keep a copy of Spec$ for later
Style = 11                     'Single line all around with a drop shadow
Clr = 112                      'Black text on white background
ScrnRow = 0                    'Center the Dialog box vertically
Action = 0                     'Not re-entrant
Choice = 1                     'Must initialize Choice to 1

CALL Dialog(Choice, Text$(), Response$(), Menu$(), ScrnRow, Style, Clr, Action)
CALL DisplayInfo(SRows, Choice, Response$())

IF Choice = 3 THEN
  ScrnRow = 0                  'Center Dialog Box vertically
  GOSUB HelpScr
END IF


'-----Dialog Box #2

Spec$ = "*.*"
Count = FCount%(Spec$)
REDIM Menu$(Count)
FOR i = 1 TO Count
  Menu$(i) = SPACE$(12)
NEXT

Menu$(0) = Spec$
CALL ReadFile(BYVAL VARPTR(Menu$(0)))
   
REDIM Text$(4)
REDIM Response$(4)
Text$(0) = " Load "
Text$(1) = "< OK >"
Text$(2) = "< Cancel >"
Text$(3) = "< Help >"
Text$(4) = "|308| File Name:"

Clr = 112
Style = 11
ScrnRow = -1
LOCATE 5, 1
Action = 0                      'not re-entrant
Choice = 1

CALL Dialog(Choice, Text$(), Response$(), Menu$(), ScrnRow, Style, Clr, Action)
CALL DisplayInfo(SRows, Choice, Response$())

IF Choice = 3 THEN
  ScrnRow = -1                  'Allow locating Dialog box vertically
  Row = 2                       'Top of Dialog box will be at row 2
  GOSUB HelpScr1
END IF

'-----Dialog Box #3

RESTORE There
REDIM Menu$(16)
FOR i = 1 TO 16
  READ Menu$(i)
NEXT

REDIM Text$(12)
REDIM Response$(12)
Text$(0) = " Pies R Us Inc. "
Text$(1) = "< OK >"
Text$(2) = "< Cancel >"
Text$(3) = "< Help >"
Text$(4) = " "
Text$(5) = "{32} Customer:"
Text$(6) = "{32} Address:"
Text$(7) = "{112} Phone:"
Text$(8) = "{106} Qty:"
Text$(9) = " "
Text$(10) = "( ) Regular crust"
Text$(11) = "( ) Cookie crust"
Text$(12) = "|5| Fillings:"

Response$(5) = "Crescent Software"
Response$(6) = "11 Bailey Avenue"
Response$(7) = "203-438-5300"
Response$(8) = "1"
Response$(10) = CHR$(7)

Temp$ = Response$(8)

Clr = 112
Style = 13      'Double line horizontally, single line vertically with shadow
ScrnRow = 0     'Center the Dialog box vertically
Choice = 1

CALL Dialog(Choice, Text$(), Response$(), Menu$(), ScrnRow, Style, Clr, Action)
CALL DisplayInfo(SRows, Choice, Response$())

IF Choice = 3 THEN
  ScrnRow = -1                'Allow locating Dialog Box vertically
  Row = 10                    'Top of Dialog box will be at row 15
  GOSUB HelpScr1
END IF


'-----Dialog Box #4

REDIM Text$(14)
REDIM Response$(14)
Text$(0) = " Change "
Text$(1) = "< Find And Verify >"
Text$(2) = "< Change All >"
Text$(3) = "< Cancel >"
Text$(4) = "< Help >"
Text$(5) = "{51} Find What:"
Text$(6) = "{51} Change To:"
Text$(7) = " "
Text$(8) = "[ ] Match Upper/Lowercase"  'The [ ] indicates a check box. Check
Text$(9) = "[ ] Whole Word"             ' boxes may appear at any line and
                                        ' need not be consecutive
Text$(10) = "                        ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿"
Text$(11) = "( ) Active Window       ³  ** CRESCENT SOFTWARE **  ³"
Text$(12) = "( ) Current Module      ³ Dialog Box by Phil Cramer ³"
Text$(13) = "( ) All Modules         ³    Copyright (c) 1990     ³"
Text$(14) = "                        ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ"
Response$(8) = "X"                      'Place an "X" in the first check box
                                        ' (Not mandatory)
Response$(11) = CHR$(7)
ScrnRow = 0
Clr = 112
Style = 11
Choice = 1

CALL Dialog(Choice, Text$(), Response$(), Menu$(), ScrnRow, Style, Clr, Action)
CALL DisplayInfo(SRows, Choice, Response$())

IF Choice = 4 THEN
  ScrnRow = -1                'Allow locating Dialog Box vertically
  Row = 10                    'Top of Dialog box will be at row 10
  GOSUB HelpScr1
END IF



'-----Dialog Box #5

REDIM Text$(9)
REDIM Response$(9)
Text$(0) = " Set Paths "
Text$(1) = "< OK >"
Text$(2) = "< Cancel >"
Text$(3) = "< Help >"
Text$(4) = " "
Text$(5) = "Search Path For:                 "
Text$(6) = "{33} Executable Files: (.Com, .Exe)"
Text$(7) = "{33} Include Files: (.Bi, .Bas)"
Text$(8) = "{33} Library Files: (.Lib, .Qlb)"
Text$(9) = "{33} Help Files: (.Hlp)"
Clr = 112
Style = 11
Response$(6) = "C:\"
Response$(7) = "C:\PRO"
Response$(8) = "C:\LIB"
ScrnRow = 0
Action = 0
Choice = 1

CALL Dialog(Choice, Text$(), Response$(), Menu$(), ScrnRow, Style, Clr, Action)
CALL DisplayInfo(SRows, Choice, Response$())

IF Choice = 3 THEN
  ScrnRow = -1                'Allow locating Dialog Box vertically
  Row = 13                    'Top of Dialog box will be at row 13
  GOSUB HelpScr
END IF



'-----Dialog Box #6

REDIM Text$(7)
REDIM Response$(0)            'May dim to 0 if no data is to be returned
Text$(1) = "< Yes >"
Text$(2) = "< No >"
Text$(3) = "< Cancel >"
Text$(4) = "< Help >"
Text$(5) = " "
Text$(6) = "One or more files are not saved. Save them now?"
Text$(7) = " "
Clr = 112
Style = 11
LOCATE 5                   'Top of Dialog box is at line 5
ScrnRow = -1
Choice = 1

CALL Dialog(Choice, Text$(), Response$(), Menu$(), ScrnRow, Style, Clr, Action)
CALL DisplayInfo(SRows, Choice, Response$())

IF Choice = 4 THEN
  ScrnRow = -1                'Allow locating Dialog Box vertically
  Row = 3                     'Top of Dialog box will be at row 3
  GOSUB HelpScr
END IF



'-----Dialog Box #7

REDIM Text$(7)
REDIM Response$(0)              'May dim to zero if no data is to be returned
Text$(1) = "< OK >"
Text$(2) = "< Cancel >"
Text$(3) = "< Help >"
Text$(4) = " "
Text$(5) = "Cannot edit Included Lines when View menu is on."
Text$(6) = "Do you want to edit this include file?"
Text$(7) = " "
Clr = 112
Style = 11
ScrnRow = -1
LOCATE 14, 1
Choice = 1

CALL Dialog(Choice, Text$(), Response$(), Menu$(), ScrnRow, Style, Clr, Action)
CALL DisplayInfo(SRows, Choice, Response$())

IF Choice = 3 THEN
  ScrnRow = -1                  'Allow locating Dialog box vertically
  Row = 2                       'Top of Dialog box will be at row 2
  GOSUB HelpScr1
END IF

Wait$ = INPUT$(1)
CALL DeinstallKeyDown           'Uninstall the Key down routine
                            '(Mandatory for QBX but not req'd for QuickBASIC)
END


'-----Dialog Box #8

HelpScr:
REDIM Text$(5)
REDIM Response$(0)            'May dim to 0 if no data is to be returned
Text$(0) = " Help  Screen "
Text$(1) = "< OK >"
Text$(2) = " "
Text$(3) = "Help?"
Text$(4) = "You've gotta' be kiddin!"
Text$(5) = " "
Style = 11
LOCATE Row                    'The column parameter is ignored
Choice = 1

CALL Dialog(Choice, Text$(), Response$(), Menu$(), ScrnRow, Style, Clr, Action)
CALL DisplayInfo(SRows, Choice, Response$())

RETURN


'-----Dialog Box #9

HelpScr1:
REDIM Text$(10)
REDIM Response$(0)            'May dim to 0 if no data is to be returned
REDIM Menu$(0)
Text$(0) = " Help  Screen #1"
Text$(1) = "< OK >"
Text$(2) = " "
Text$(3) = "Notice how plain text lines are automatically centered."
Text$(4) = "You may left justify them by padding the end...          "
Text$(5) = "               Or right justify by padding the beginning."
Text$(6) = " "
Text$(7) = "The Dialog box will automatically size itself "
Text$(8) = "based on the longest string/field and the number"
Text$(9) = "of strings/fields"
Text$(10) = " "
Style = 11
LOCATE Row, 1                 'The column parameter is ignored
Choice = 1

CALL Dialog(Choice, Text$(), Response$(), Menu$(), ScrnRow, Style, Clr, Action)
CALL DisplayInfo(SRows, Choice, Response$())
RETURN

'Data statements for Dialog Box #3
There:
DATA "apple     ","apricot   ","blueberry ","cat feet  ","cherry    "
DATA "cheesecake","chocolate ","keylime   ","lemon     ","mincemeat "
DATA "pecan     ","pumpkin   ","pineapple ","rhubarb   ","strawberry"
DATA "tuna      "

SUB DisplayInfo (Row, Choice, Response$())

  LOCATE Row - 2, 1
  CALL QPrint0("Data returned form previous Dialog box:", 30)
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

