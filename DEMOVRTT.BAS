'********** DemoVrtT.Bas - demonstrates VertMenT

'Copyright (c) 1988 Don Malin & Crescent Software


DEFINT A-Z

DECLARE FUNCTION FCount% (FileSpec$)
DECLARE FUNCTION Monitor% ()
DECLARE SUB ReadFileT (FileSpec$, SEG Element AS ANY)
DECLARE SUB VertMenuT (Items() AS ANY, Choice, BoxBot, Ky$, Action, Cnf AS ANY)


'The first $Include file contains a structure definition for the menu and
'screen colors.  The second $Include determines the type of monitor you
'are using and assigns the appropriate colors.
'
'$INCLUDE: 'DefCnf.BI'
'$INCLUDE: 'SetCnf.BI'

'The only way to pass a fixed-length string array to a subprograms is
'to first declare it as a TYPE array, as shown below.  If you intend to
'change the length from 12 as used in this demo, then you must also
'modify the TYPE statement in the VERTMENT.BAS disk file.

TYPE FLen
   V AS STRING * 12             'this makes a 12 character string
END TYPE

CLS
CALL InitMouse(MouseThere)      'turn the mouse cursor on (Optional)
CALL ShowCursor

FileSpec$ = "*.*"
NumEls = FCount%(FileSpec$)             'see how many files match "*.*"
REDIM FileNames(1 TO NumEls) AS FLen    'dimension the array using the TYPE
ReadFileT FileSpec$, FileNames(1)       'fill the array with file names

BoxBot = 20             'limit the box length to go no lower than line 20
Action = 0              '0 means stay in the menu until they select something

Choice = 1              'you may pre-load any choice to highlight initially
LOCATE 3, 1             'set the upper left corner for the menu
CALL VertMenuT(FileNames(), Choice, BoxBot, Ky$, Action, Cnf)

LOCATE 1, 1
CALL HideCursor
PRINT "File number"; Choice; "was selected: "; FileNames(Choice).V
IF Ky$ = CHR$(27) THEN PRINT " - Escape was pressed"

