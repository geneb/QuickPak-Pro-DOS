'********* DEMOSCRL.BAS - demonstrates the ScrollIn scrollable input routine

'Copyright (c) 1991 Crescent Software
'Written by Phil Cramer

DEFINT A-Z

DECLARE SUB ScrollIn (Edit$, Start, Wide, MaxLen, Filter, Ky, EdClr, Clr)
DECLARE SUB QPrint0 (A$, Clr)
DECLARE SUB InitMouse (There)
DECLARE SUB HideCursor ()
DECLARE SUB ShowCursor ()

CLS
CALL InitMouse(There)                           'Initialize the Mouse driver
CALL ShowCursor                                 'Turn on the Mouse cursor

LOCATE 2, 2: QPrint0 "Scrollable Text:", 15     'Display some stuff
LOCATE 3, 2: QPrint0 "Non-Scrollable Text:", 15
LOCATE 4, 2: QPrint0 "Integers ONLY:", 15
LOCATE 5, 2: QPrint0 "Single/Double ONLY:", 15
LOCATE 6, 2: QPrint0 "Caps or Nums ONLY:", 15
                                                'First edit string
Edit$ = "This Demo shows ScrollIn in operation. If the MaxLen argument is greater than the Wide argument, the edit field may be scrolled left or right using any of the standard editing keys. "
Edit$ = Edit$ + "The left and right arrow keys move the cursor right or left one character. Tab moves the cursor ahead 8 characters at a time, while Shift + Tab moves the cursor backwards 8 "
Edit$ = Edit$ + "characters. Ctrl-Right or Ctrl-Left move the cursor Wide spaces -1 left or right. Home locates the cursor at the first character in the edit string. "
Edit$ = Edit$ + "End will find and locate the cursor at the last non-space character in the string. ScrollIn may be exited by pressing Enter, PgUp, PgDn, Up arrow, or the Down Arrow. "
Edit$ = Edit$ + "Pressing Escape will exit ScrollIn, and return the original unedited string. Pressing Alt-C clears the field while Alt-R restores the original contents."

EdClr = 31                        'While editing, white text/blue background
Clr = 10                          'Done editing, green text, black background

Start = 1                         'Start at first character in the edit string
Wide = 50                         'Make the edit window 50 spaces wide
MaxLen = 900                      'Maximum allowable length of the string
Filter = 0                        'Accept all keys
LOCATE 2, 23                      'Locate the edit field
Ky = 6                            'Start editing at the sixth column

CALL ScrollIn(Edit$, Start, Wide, MaxLen, Filter, Ky, EdClr, Clr)

Start = 1
Wide = 50                         'MaxLen = Wide, Do not scroll window
MaxLen = 50
Filter = 0

LOCATE 3, 23                      'position the left edge of the field
Ky = 1

CALL ScrollIn(Edit$, Start, Wide, MaxLen, Filter, Ky, EdClr, Clr)


Start = 1
Wide = 8
MaxLen = 8
Filter = 1                        'Filter = 1, Accept integer characters only
LOCATE 4, 23
Ky = 1                            'start editing at the first character

Edit$ = "125"
CALL ScrollIn(Edit$, Start, Wide, MaxLen, Filter, Ky, EdClr, Clr)


Start = 1
Wide = 12
MaxLen = 12
Filter = 2                        'Filter = 2, Accept single/double prec. only
LOCATE 5, 23
Ky = 1

Edit$ = "3.37E+38"
CALL ScrollIn(Edit$, Start, Wide, MaxLen, Filter, Ky, EdClr, Clr)


Start = 1
Wide = 50
MaxLen = 100
Filter = 4                        'Filter = 4, Capitalize all letters
LOCATE 6, 23
Ky = 1

Edit$ = "CAPS OR NUMBERS PLEASE"
CALL ScrollIn(Edit$, Start, Wide, MaxLen, Filter, Ky, EdClr, Clr)

CALL HideCursor

