'********** VIRTUAL.BAS - shows how to create virtual screens using SetMonSeg

'Copyright (c) 1991 Ethan Winer


' Note the way the virtual screen is cleared using the Fill2 routine.  When
' a display screen is to be cleared, each character position is filled with
' a CHR$(32) blank space (&H20), and its corresponding color byte is set to
' 7 (white on black).  Hex values are used here to simplify assigning the
' two bytes in one operation.  To clear the screen to white characters on a
' blue background you would instead use &H1720 as the fill color.  The chart
' below shows the relationship between the Hex values and the screen colors.
'
'                            &H4741
'                              ||||
'      background (red) -------+|++------- fill character (&H41 = 65)
'    foreground (white) --------+
'
' In this example, the background is red and the fill character is an "A".
' Note that the foreground flashing is stored in the highest bit of the
' background color.  Therefore, if the background color is greater than 7,
' the background will actually be Color MOD 8 and the foreground will flash.
'
' IMPORTANT: As arrays are created and erased, BASIC may move existing arrays
' around in memory.  Therefore, you may need to call SetMonSeg using VARSEG
' later on after subsequent REDIM or ERASE statements.  This is not necessary
' between successive calls to the QuickPak video routines.


DEFINT A-Z

REDIM Array%(1 TO 2000)                         'create the virtual screen
CALL Fill2(SEG Array(1), &H720, 2000)           'clear it to spaces/color 7

CALL SetMonSeg(VARSEG(Array(1)))                'make that the active segment
CALL QPrintRC("This is a test", 10, 20, 112)    'print a test message there

CALL SetMonSeg(0)                               'switch to the real segment
CALL ScrnRest0(1, 1, 25, 80, SEG Array(1))      'and "restore" what we wrote
