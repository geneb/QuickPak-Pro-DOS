'********** DEMOPLMS.BAS - pull down menu demonstration program

'by Donald R. Malin
'Copyright (c) 1987-1990 Crescent Software


DEFINT A-Z

DECLARE FUNCTION Monitor% ()
DECLARE FUNCTION PullMenKey% (Ky$, Menu$(), Stat())

DECLARE SUB BarPrint (Choice$(), Stat%())
DECLARE SUB HideCursor ()
DECLARE SUB InitMouse (MouseThere%)
DECLARE SUB MQPrint (X$, Colr%)
DECLARE SUB PullDnMs (Menu$(), Stat(), Menu%, Choice%, Ky$, Action%)
DECLARE SUB SetCursor (Row, Col)
DECLARE SUB ShowCursor ()
DECLARE SUB TextCursor (FG%, BG%)


CLS

InitMouse Temp                          'Define the Mouse cursor
TextCursor -2, 4                        'Inverse foreground red background
SetCursor 1, 1                          'Locate it at upper right of screen
ShowCursor                              'Turn it on

LOCATE 2
MQPrint STRING$(23 * 80, "²"), 7        'Make a background for the demo
LOCATE 25, 1                            'Print instructions
MQPrint "Hold the [Alt] key down and then press the first letter of the desired menu.    ", 112
LOCATE 13, 41, 1


'----- Define the Menu Choices here
REDIM Menu$(15, 8)                      'Allocate space for the Menu Choices
REDIM Stat(15, 8)                       'Define the choice status array

'To set the "Hot Key" character for a menu choice, set the High byte of the
'corresponding element of the "Stat()" array to the offset into the string
'of the letter.
'
'Example: Make the "A" hot in "Save As...".
'
'                  0123456789
'   Menu$(5, 0) = "Save As..."
'                ÚÄÄÄÄÄÄÙ
'   Stat(5, 0) = 5 * 256 + 1
'                          ^ Optional to make the choice inactive.
'
'If you later want to reset the status (active/inactive) without affecting
'the hot key position in the high byte, use the "SetStatus" sub program as
'follows:
'
'Status = LEN(FileName$) = 0          'Can't save a file until one is loaded
'CALL SetStatus(Stat(5, 0), Status)   'If there was no file name, choice 5
'                                     '  of menu 0 will be made inactive.

'----- Define the menus
Menu$(0, 0) = "File"
Menu$(1, 0) = "New Program"
Menu$(2, 0) = "Open Program..."
Menu$(3, 0) = "Merge..."
Menu$(4, 0) = "Save"
 Stat(4, 0) = 1
Menu$(5, 0) = "Save As..."
 Stat(5, 0) = 5 * 256
Menu$(6, 0) = "Save All"
 Stat(6, 0) = 2 * 256
Menu$(7, 0) = "-"
Menu$(8, 0) = "Create File..."
Menu$(9, 0) = "Load File..."
Menu$(10, 0) = "Unload File..."
 Stat(10, 0) = 1
Menu$(11, 0) = "-"
Menu$(12, 0) = "Print"
Menu$(13, 0) = "DOS Shell"
Menu$(14, 0) = "-"
Menu$(15, 0) = "Exit"
 Stat(15, 0) = 256

Menu$(0, 1) = "Edit"
Menu$(1, 1) = "Undo   Alt+Backspace"
 Stat(1, 1) = 1
Menu$(2, 1) = "Cut        Shift+Del"
 Stat(2, 1) = 2 * 256 + 1
Menu$(3, 1) = "Copy        Ctrl+Ins"
 Stat(3, 1) = 1
Menu$(4, 1) = "Paste      Shift+Ins"
 Stat(4, 1) = 1
Menu$(5, 1) = "Clear            Del"
 Stat(5, 1) = 2 * 256 + 1
Menu$(6, 1) = "-"
Menu$(7, 1) = "New SUB..."
 Stat(7, 1) = 4 * 256
Menu$(8, 1) = "New FUNCTION..."
 Stat(8, 1) = 4 * 256

Menu$(0, 2) = "View"
Menu$(1, 2) = "SUBS...         F2"
Menu$(2, 2) = "Next SUB  Shift+F2"
 Stat(2, 2) = 1 * 256
Menu$(3, 2) = "Split"
 Stat(3, 2) = 1 * 256
Menu$(4, 2) = "-"
Menu$(5, 2) = "Next Statement"
 Stat(5, 2) = 1
Menu$(6, 2) = "Output Screen   F4"
 Stat(6, 2) = 1 * 256
Menu$(7, 2) = "-"
Menu$(8, 2) = "Included File"
 Stat(8, 2) = 1
Menu$(9, 2) = "Included Lines"
 Stat(9, 2) = 9 * 256

Menu$(0, 3) = "Search"
Menu$(1, 3) = "Find..."
Menu$(2, 3) = "Selected Text     Ctrl+\"
Menu$(3, 3) = "Repeat Last Find      F3"
Menu$(4, 3) = "Change..."
Menu$(5, 3) = "Label"

Menu$(0, 4) = "Run"
Menu$(1, 4) = "Start     Shift+F5"
Menu$(2, 4) = "Restart"
Menu$(3, 4) = "Continue        F5"
 Stat(3, 4) = 2 * 256
Menu$(4, 4) = "Modify COMMAND$..."
 Stat(4, 4) = 7 * 256
Menu$(5, 4) = "-"
Menu$(6, 4) = "Make EXE File..."
 Stat(6, 4) = 6 * 256
Menu$(7, 4) = "Make Library..."
 Stat(7, 4) = 5 * 256
Menu$(8, 4) = "-"
Menu$(9, 4) = "Set Main Module..."
 Stat(9, 4) = 4 * 256

Menu$(0, 5) = "Debug"
Menu$(1, 5) = "Add Watch..."
Menu$(2, 5) = "Instant Watch...   Shift+F9"
Menu$(3, 5) = "Watchpoint..."
Menu$(4, 5) = "Delete Watch..."
Menu$(5, 5) = "Delete All Watch"
 Stat(5, 5) = 2 * 256
Menu$(6, 5) = "-"
Menu$(7, 5) = "Trace On"
Menu$(8, 5) = "History On"
Menu$(9, 5) = "-"
Menu$(10, 5) = "Toggle Breakpoint        F9"
 Stat(10, 5) = 7 * 256
Menu$(11, 5) = "Clear All BreakPoints"
Menu$(12, 5) = "Break on Errors"
 Stat(12, 5) = 9 * 256
Menu$(13, 5) = "Set Next Statement"
 Stat(13, 5) = 1

Menu$(0, 6) = "Calls"
Menu$(1, 6) = "DEMOPULL.BAS"

Menu$(0, 7) = "Options"
Menu$(1, 7) = " Display..."
 Stat(1, 7) = 1 * 256
Menu$(2, 7) = " Set Paths..."
 Stat(2, 7) = 5 * 256
Menu$(3, 7) = " Right Mouse..."
 Stat(3, 7) = 7 * 256
Menu$(4, 7) = "Syntax Checking"
 Stat(4, 7) = 1 * 256
Menu$(5, 7) = "Full Menus"
 Stat(5, 7) = 1 * 256

Menu$(0, 8) = "Help"
Stat(0, 8) = 17


BarPrint Menu$(), Stat()                'Display the menu bar and build a
                                        '  table of Hot Keys for menu bar.

Action = 0                              'Action 0 (no polling) is the easiest
                                        '  way to use PullDown.

DO
   LOCATE 13, 41, 0

   Ky$ = INKEY$                         'Get a key press from the buffer
                                        'See if it's a hot-key or mouse
                                        '  pressed on menu bar.
   Menu = PullMenKey(Ky$, Menu$(), Stat())
   IF Menu > -1 THEN                    'Yes
                                        
      PullDnMs Menu$(), Stat(), Menu, Choice, Ky$, Action

      LOCATE 24, 1
      PRINT "Selection"; Choice; "was made from Menu"; Menu;

      '----- Code to handle the selection would go here
      '----- Example:
      'SELECT CASE Menu                  'Branch according to "Menu"
      '   '----- File Menu
      '   CASE 0
      '      SELECT CASE Choice          'Branch according to "Choice"
      '         '----- New Program
      '         CASE 1
      '            NewProgram            'Call your "NewProgram" procedure
      '         '----- Open Program
      '         CASE 2
      '            OpenProgram           'Call your "OpenProgram" procedure
      'Etc.



   END IF

   '----- Your code to handle key presses would go here
   '..
   '..

LOOP UNTIL (Menu = 0 AND Choice = 15) OR Ky$ = CHR$(27)

HideCursor                              'Turn the mouse cursor off
END

