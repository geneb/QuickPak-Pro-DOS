'********** DemoVert.Bas - demonstrates VertMenu

'Copyright (c) 1988 Don Malin & Crescent Software


DEFINT A-Z
DECLARE FUNCTION Monitor% ()
DECLARE SUB ShowCursor ()
DECLARE SUB HideCursor ()
DECLARE SUB TextCursor (FG, BG)
DECLARE SUB VertMenu (Item$(), Choice, MaxLen, BoxBot, Ky$, Action, Cnf AS ANY)


'The first $Include file contains a structure definition for the menu and
'screen colors.  The second $Include determines the type of monitor you
'are using and assigns the appropriate colors.
'
'$INCLUDE: 'DefCnf.BI'
'$INCLUDE: 'SetCnf.BI'

CLS
MaxLen = 9              'this is the menu width
BoxBot = 20             'limit the box length to go no lower than line 20
Action = 0              '0 means stay in the menu until they select something

DIM Choice$(80)         'dimension the choices

FOR X = 1 TO 80
    READ Choice$(X)
NEXT

DATA "Choice  1", "Moist   2", "Roast   3", "Toast   4", "Most    5"
DATA "Boast   6", "Ghost   7", "Post    8", "Past    9", "Last   10"
DATA "Raft   11", "Graft  12", "Rhyme  13", "Time   14", "Mine   15"
DATA "Line   16", "Sign   17", "Benign 18", "Tine   19", "Divine 20"
DATA "Crime  21", "Choice 22", "Choice 23", "Choice 24", "Choice 25"
DATA "Choice 26", "Choice 27", "Choice 28", "Choice 29", "Choice 30"
DATA "Choice 31", "Choice 32", "Choice 33", "Choice 34", "Choice 35"
DATA "Choice 36", "Choice 37", "Choice 38", "Choice 39", "Choice 40"
DATA "Choice 41", "Choice 42", "Choice 43", "Choice 44", "Choice 45"
DATA "Choice 46", "Choice 47", "Choice 48", "Choice 49", "Choice 50"
DATA "Choice 51", "Choice 52", "Choice 53", "Choice 54", "Choice 55"
DATA "Choice 56", "Choice 57", "Choice 58", "Choice 59", "Choice 60"
DATA "Choice 61", "Choice 62", "Choice 63", "Choice 64", "Choice 65"
DATA "Choice 66", "Choice 67", "Choice 68", "Choice 69", "Choice 70"
DATA "Choice 71", "Choice 72", "Choice 73", "Choice 74", "Choice 75"
DATA "Choice 76", "Choice 77", "Choice 78", "Choice 79", "Choice 80"

'Choice = 12            'you could pre-load choice to highlight automatically
LOCATE 3, 1, 0          'set upper left corner of menu, turn off the cursor
TextCursor -2, -2       'define the Mouse cursor
ShowCursor
CALL VertMenu(Choice$(), Choice, MaxLen, BoxBot, Ky$, Action, Cnf)
HideCursor

LOCATE 1, 1
PRINT "Choice Number"; Choice; "was selected";
IF Ky$ = CHR$(27) THEN PRINT " - Escape was pressed"

