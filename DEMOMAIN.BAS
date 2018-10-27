'********** DEMOMAIN.BAS - main menu subprogram demonstration

'Copyright (c) 1987 Ethan Winer


DEFINT A-Z
DECLARE SUB MainMenu (Item$(), Choice, Colr)

CLS
DIM Choice$(8)                          'dimension the choices array

FOR X = 1 TO 8                          'assign each item to be displayed
    READ Choice$(X)
NEXT
DATA "Enter Sales Data"
DATA "Enter Region Data"
DATA "Enter Data by Category"
DATA "Print All Reports by City"
DATA "Print All Reports by State"
DATA "Print All Reports by Sales Category"
DATA "Crash the System"
DATA "Return to Main Menu"

LOCATE , , 0                            'turn off the cursor please!
Colr = 7                                'combined foreground/background color
CALL MainMenu(Choice$(), Choice, Colr)

LOCATE 24, 1: PRINT "Item Number"; Choice; "Was Selected";
IF Choice = 0 THEN PRINT " - Escape was pressed";

