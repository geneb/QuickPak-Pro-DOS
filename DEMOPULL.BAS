'********** DemoPull.Bas - pull down menu demonstration program

'Copyright (c) 1987 Donald R. Malin
'Copyright (c) 1987 Crescent Software


DEFINT A-Z
DECLARE SUB BarPrint (Choice$(), BarColor)
DECLARE FUNCTION Monitor% ()
DECLARE SUB PullDown (Choice$(), Stat(), Menu, Choice, Ky$, Action, Cnf AS ANY)
DECLARE SUB QPrint0 (X$, Colr)
DECLARE SUB ShowCursor ()
DECLARE SUB HideCursor ()


'The first $Include file contains a structure definition for menu and
'screen colors.  The second $Include determines the type of monitor you
'are using and assigns appropriate colors.
'
'$INCLUDE: 'DefCnf.BI'
'$INCLUDE: 'SetCnf.BI'

CLS
QPrint0 STRING$(22 * 80, "þ"), 23       'make a background for the demo


'----- Define the Menu Choices here
REDIM Stat(16, 8)                       'define the choice status array
Stat(12, 1) = 1                         'this is how you'd deactivate an item
					'  in this case, item 12 in menu 1

REDIM Choice$(16, 8)                    'Allocate space for the Menu Choices
FOR C = 0 TO 16                         'read the Menu Choices into the Array
    FOR M = 1 TO 8
	READ Choice$(C, M)              'read the list of choices
    NEXT
NEXT

DATA "File",            "Edit",                 "View",               "Search",                   "Run",                "Debug",                   "Calls",        "F1=Help"
DATA "New Program",     "Undo   Alt+Backspace", "SUBS...         F2", "Find...",                  "Start     Shift+F5", "Add Watch...",            "DEMOPULL.BAS", ""
DATA "Open Program...", "Cut        Shift+Del", "Next SUB  Shift+F2", "Selected Text     Ctrl+\", "Restart",            "Watchpoint...",           "",             ""
DATA "Merge...",        "Copy        Ctrl+Ins", "Split",              "Repeat Last Find      F3", "Continue        F5", "Delete Watch...",         "",             ""
DATA "Save",            "Paste      Shift+Ins", "-",                  "Change...",                "Modify COMMAND$...", "Delete All Watch",        "",             ""
DATA "Save As...",      "-",                    "Next Statement",     "Label",                    "-",                  "-",                       "",             ""
DATA "Save All",        "New SUB...",           "Output Screen   F4", "",                         "Make EXE File...",   "Trace On",                "",             ""
DATA "-",               "New FUNCTION...",      "-",                  "",                         "Make Library...",    "History On",              "",             ""
DATA "Create File...",  "-",                    "Include File",       "",                         "",                   "-",                       "",             ""
DATA "Load File...",    "û Syntax Checking",    "Included Lines",     "",                         "",                   "Toggle Breakpoint    F9", "",             ""
DATA "Unload File...",  "",                     "-",                  "",                         "",                   "Clear All BreakPoints",   "",             ""
DATA "-",               "",                     "Options...",         "",                         "",                   "Set Next Statement",      "",             ""
DATA "Print",           "",                     "",                   "",                         "",                   "",                        "",             ""
DATA "-",               "",                     "",                   "",                         "",                   "",                        "",             ""
DATA "DOS Shell",       "",                     "",                   "",                         "",                   "",                        "",             ""
DATA "-",               "",                     "",                   "",                         "",                   "",                        "",             ""
DATA "Exit",            "",                     "",                   "",                         "",                   "",                        "",             ""

Choice$(0, 0) = "ð"       'This is the old Microsoft Help Icon.  There are no
			  'choices for this selection.  This is to illustrate
			  'that you may include a choice that has no menu,
			  'when there are no further options.


Action = 0                'Action 0 is the easiest way to use PullDown
Menu = 1                  'start PullDown by displaying Menu 1
Choice = 1                'start with Choice #1 highlighted

ShowCursor
CALL PullDown(Choice$(), Stat(), Menu, Choice, Ky$, Action, Cnf)
HideCursor

LOCATE 24, 1
PRINT "Selection"; Choice; "was made from Menu"; Menu;
IF Ky$ = CHR$(27) THEN PRINT "- Escape was pressed";

