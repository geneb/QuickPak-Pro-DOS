'************ DEMOCM.BAS - demonstrates Chris May's assembler routines

'Copyright (c) 1989 Chris May
'Copyright (c) 1989 Crescent Software


DEFINT A-Z

DECLARE FUNCTION FCount% (FSpec$)
DECLARE FUNCTION FUsing$ (Number$, Image$)
DECLARE SUB AMenu (BYVAL Address, Start, Count, ScanCode, FileColr, HiLiteColr, Rows, Columns, Spacing, Row, Column)
DECLARE SUB Box (ULRow, ULCol, LRRow, LRCol, Style, BoxColor, Page)
DECLARE SUB DirFile (BYVAL Address, Count, ScanCode, MessageColor, FileColor, HiLite, BoxColor)
DECLARE SUB Editor (Edit$, Length, ScanCode, NumOnly, CapsOn, NormColor, EditColor, Row, Column)
DECLARE SUB MenuVert (BYVAL Address, NLines, ScanCode, Choice, NormClr, HiLite, Row, Column)
DECLARE SUB ReadFile (BYVAL Address)
DECLARE SUB PUsing (Number$, Image$, Color1, Color2, Page, Row, Column)
DECLARE SUB YesNo (YN$, Prompt$, ScanCode, NormalColr, EditColr, Row, Column)

CLS

'--- first do an exploding box

LOCATE 25, 1, 1
PRINT "Press a key ";
WHILE INKEY$ = "": WEND
BoxColor = 9

FOR Row = 1 TO 11
    CALL Box(12 - Row, 39 - Row * 3, 12 + Row, 41 + Row * 3, Row, BoxColor, -1)
    PLAY "MFT255P32"            'VERY short delay
NEXT



'--- now let's look at Chris' editor

Max = 35                'the maximum number of characters to accept
NumOnly = 0             'allow both letters and numbers
CapsOn = 0              'don't automatically capitalize letters
EditColor = 112         'use color 112 (black on white) while editing
NormColor = 7           'restore the field to color 7 when done

FSpec$ = "C:*.*"                                'initial string for editing
FSpec$ = FSpec$ + SPACE$(Max - LEN(FSpec$))     'pad with spaces to the
						'desired length
LOCATE 25, 1, 0
PRINT "Now enter a file spec: "; '
CALL Editor(FSpec$, Length, ScanCode, NumOnly, CapsOn, NormColor, EditColor, 25, 24)
FSpec$ = LEFT$(FSpec$, Length)  'keep only as much as Editor says was entered



'--- take the file spec that was entered, and read all matching file names

Count = FCount%(FSpec$)         'first count the number of matching files
IF Count = 0 THEN END           'spec must have been invalid
N = Count                       'save the count in N for later
DIM Array$(Count)               'dim a string array to hold the file names
Array$(0) = FSpec$              'put the file spec into element zero

FOR X = 1 TO Count                      'make room for the names
    Array$(X) = SPACE$(12)
NEXT
CALL ReadFile(VARPTR(Array$(0)))        'get the file names


'--- show how to select file names using the DirFile menu routine

MessageColor = 9                'DirFile's message color
FileColor = 112                 'color for showing the files
HiLite = 23                     'the highlighted file's color
BoxColor = 118                  'the color to use for the surrounding box

CLS                             'clear the screen of any previous messages
CALL DirFile(VARPTR(Array$(1)), Count, ScanCode, MessageColor, FileColor, HiLite, BoxColor)

SELECT CASE ScanCode                    'see how DirFile was exited
   CASE 13                              'Enter was pressed
      PRINT "File #"; Count; "was selected: "; Array$(Count)
   CASE 27                              'Escape was pressed
      PRINT "Escape was pressed"
   CASE ELSE
      IF ScanCode > 0 THEN              'a normal key was pressed
	 PRINT "Control Key #"; ScanCode; "was pressed"
      ELSE                              'an extended key was pressed
	 PRINT "Keyboard Scan Code #"; -ScanCode; "was pressed"
      END IF                            '"-" flips ScanCode to positive value
END SELECT



'--- now show how AMenu works

PRINT
PRINT "Press any key to see AMenu at work"
WHILE INKEY$ = "": WEND

Count = N       'reset Count to the number of files read earlier
		'(DirFile returns the selected item number in Count)
CLS             'start this demo with a clean slate
PRINT "Number of rows and columns in table is limited only by screen size"
CALL AMenu(VARPTR(Array$(1)), 1, Count, ScanCode, 112, 23, 10, 3, 2, 7, 15)
'                                                  ^    ^   ^  ^  ^  ^   ^
'                                                  ³    ³   ³  ³  ³  ³   ³
'              File color ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ    ³   ³  ³  ³  ³   ³
'              Hilight color ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ   ³  ³  ³  ³   ³
'              Number of rows in table ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ  ³  ³  ³   ³
'              Number of columns in table ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ  ³  ³   ³
'              Number of spaces between columns ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ  ³   ³
'              Upper left row of display        ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ   ³
'              Upper left column of display     ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

LOCATE 2, 1
SELECT CASE ScanCode                    'see how AMenu was exited
   CASE 13                              'Enter was pressed
      PRINT "File #"; Count; "was selected: "; Array$(Count)
   CASE 27                              'Escape was pressed
      PRINT "Escape was pressed"
   CASE ELSE
      IF ScanCode > 0 THEN              'a normal key was pressed
	 PRINT "Control Key #"; ScanCode; "was pressed"
      ELSE                              'an extended key was pressed
	 PRINT "Keyboard Scan Code #"; -ScanCode; "was pressed"
      END IF                            '"-" flips ScanCode to positive value
END SELECT
LOCATE 25, 1: PRINT "Press any key";
WHILE INKEY$ = "": WEND



'--- now show how to use AMenu for "tagging" multiple items

CLS
PRINT "This demonstrates a file tagging technique using AMenu"
PRINT "Press Enter to toggle item tagging, Escape when done"

FOR I = 1 TO N                          'add two leading blanks to each string
    Array$(I) = "  " + Array$(I)        'to make room for a "check mark"
NEXT
Count = N                               'reset Count to the number of files

DO                                      'loop until they press Escape

   CALL AMenu(VARPTR(Array$(1)), 1, Count, ScanCode, 112, 23, 15, 3, 4, 7, 15)
   SELECT CASE ScanCode                 'see what key they pressed
      CASE 13, 32                       'Enter or Space, toggle the item
	 IF LEFT$(Array$(Count), 1) = " " THEN  'it's not marked, mark it
	    MID$(Array$(Count), 1, 1) = "û"     '<---- use any marker you want
	 ELSE
	    MID$(Array$(Count), 1, 1) = " "     'unmark the item
	 END IF
      CASE ELSE
   END SELECT

   IF ScanCode <> 27 THEN ScanCode = 3  'We must set ScanCode to 3 to tell
					'  AMenu that we are re-entering it,
					'  and not to start at item one.
LOOP UNTIL ScanCode = 27



'--- show how MenuVert works

CLS
PRINT "This demonstrates a vertical menuing program"
Row = 7                         'where to display the menu's upper left corner
Column = 13
ScanCode = N                    'on entry, set ScanCode to the number of items
NumLines = 15                   'how high to make the visible portion
Choice = 1                      'start by highlighting choice number 1
NormClr = 112                   'the menu window color
HiLite = 23                     'the color to use for highlighting

CALL MenuVert(VARPTR(Array$(1)), NumLines, ScanCode, Choice, NormClr, HiLite, Row, Column)
LOCATE 2, 1
PRINT "ScanCode = "; ScanCode
PRINT "Choice   = "; Choice

LOCATE 25, 1: PRINT "Press any key";
WHILE INKEY$ = "": WEND
CLS



'--- now show PUsing and FUsing in operation

INPUT "Now enter a number: ", X#
Image$ = "This is how PUsing formats a number: $$######,.### - nice, right?"
CALL PUsing(STR$(X#), Image$, 9, 113, -1, 3, 1)

Image$ = "$$######,.###"
X$ = FUsing$(STR$(X#), Image$)
LOCATE 7, 1                             'compare FUsing, STR$, and PRINT USING
PRINT "And here's the same thing done by FUsing: "; X$
PRINT "And here's BASIC STR$(): "; STR$(X#)
PRINT USING "Here's BASIC Print Using: $$######,.###"; X#
WHILE INKEY$ = "": WEND



'--- finally, show how YesNo is used

CLS
Msg$ = "Do you want to see another demo? (Yes/No) "
YN$ = "N"
CALL YesNo(YN$, Msg$, ScanCode, 7, 112, 1, 1)
LOCATE 5, 1

IF YN$ = "Y" THEN
   PRINT "That was a demo of YesNo!"
ELSEIF YN$ = "N" THEN
   PRINT "Well you just did anyway -- that was a demo of YesNo!"
END IF

IF ScanCode > 0 THEN PRINT "Control Key #"; ScanCode; "was pressed"
IF ScanCode < 0 THEN PRINT "Keyboard Scan Code #"; -ScanCode; "was pressed"
PRINT
PRINT "YN$ = "; YN$

