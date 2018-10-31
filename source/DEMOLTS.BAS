'********** DEMOLTS.BAS - demo of the Lotus(tm) style menu subprograms

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z
DECLARE SUB LtsMenu (Item$(), Choice, Colr)
DECLARE SUB Lts2Menu (Item$(), Prompt$(), Choice, Colr)
DECLARE SUB QPrint (X$, Colr, Page)


'----- show how Lts2Menu works

REDIM Choice$(10), Prompt$(10)
FOR X = 1 TO 10
    READ Choice$(X)
    READ Prompt$(X)
NEXT

DATA Worksheet
DATA "Global, Insert, Delete, Column, Erase, Titles, Window, Status, Page"
DATA Range
DATA "Format, Label, Erase, Name, Justify, Protect, Input, Value, Transpose"
DATA Copy
DATA "Copy a cell or range of cells"
DATA Move
DATA "Move a cell or range of cells"
DATA File
DATA "Retrieve, Save, Combine, Xtract, Erase, List, Import, Directory"
DATA Print
DATA Output a range to the printer or a print file
DATA Graph
DATA Create a graph
DATA Data
DATA "Fill, Table, Sort, Query, Distribution, Matrix, Regression, Parse"
DATA System
DATA "Invoke the DOS Command Interpreter"
DATA Quit
DATA "End 1-2-3 session (Have you saved your work?)"

CLS
LOCATE 1, 1: CALL QPrint(STRING$(80, "Í"), 3, -1)   'frame choices - optional
LOCATE 4, 1: CALL QPrint(STRING$(80, "Í"), 3, -1)
LOCATE 20, 1: PRINT "Use the arrow keys or the first letter of a choice."
LOCATE 21, 1: PRINT "Then press Enter to make a selection, or press Escape to cancel."
LOCATE 2, 1: CALL Lts2Menu(Choice$(), Prompt$(), Choice, 15)

CLS
LOCATE 23, 1: PRINT "Choice number"; Choice; "was selected";
IF Choice = 0 THEN PRINT " - Escape was pressed";
LOCATE 25, 1: PRINT "Press a key to see the next demonstration ";
CALL WaitKey



'----- now show the regular Lotus menu

REDIM Choice$(200)      'use 200 to show how LtsMenu ignores the blank ones
FOR X = 1 TO 20         '  at the end of the array
    READ Choice$(X)
NEXT

DATA "Choice 1",  "This is Choice 2",  "Ch 3",  "C4",  "And Here's Choice 5"
DATA "Choice 6 is Nice",  "Number 7",  "Here's Choice 8",  "Big Number Nine"
DATA "Choice 10", "Choice 11", "Choice 12", "Choice 13", "Choice 14"
DATA "Choice 15", "Choice 16", "Choice 17", "Choice 18", "Choice 19"
DATA "Choice 20"

CLS
LOCATE 1, 1: QPrint STRING$(80, "Í"), 2, -1     'frame the choices - optional
LOCATE 3, 1: QPrint STRING$(80, "Í"), 2, -1
LOCATE 20, 1: PRINT "Use the arrow keys or the first letter of a choice."
LOCATE 21, 1: PRINT "Then press Enter to select it, or press Escape to cancel."

LOCATE 2, 1
CALL LtsMenu(Choice$(), Choice, 10)
CLS
LOCATE 23, 1: PRINT "Choice number"; Choice; "was selected";
IF Choice = 0 THEN PRINT " - Escape was pressed";

