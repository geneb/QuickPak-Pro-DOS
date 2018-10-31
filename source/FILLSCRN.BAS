'********** FillScrn.Bas

'Copyright (c) 1989 Ethan Winer


DEFINT A-Z
DECLARE SUB FillScrn (ULRow, ULCol, LRRow, LRCol, Colr, Char, Page)
DECLARE SUB Pause (Ticks)
DECLARE FUNCTION Rand% (Hi, Lo)

CLS
LOCATE 25
PRINT "Press a key to stop the madness";

DO
    ULRow = Rand%(1, 24)                'pick a random number between 1 and 24
    ULCol = Rand%(1, 80)                'use 1 to 80 for the columns
    LRRow = Rand%(1, 24)
    LRCol = Rand%(1, 80)
    IF ULCol > LRCol THEN SWAP ULCol, LRCol     'force ULCol less than LRCol
    IF ULRow > LRRow THEN SWAP ULRow, LRRow     'ditto for the rows
    Colr = Rand%(1, 127)                        'make a random color
    Char = Rand%(1, 254)                        'and a random character
    Page = -1                                   'use the default page
    FillScrn ULRow, ULCol, LRRow, LRCol, Colr, Char, Page
    Pause 1
LOOP UNTIL LEN(INKEY$)

FUNCTION Rand% (Lo, Hi) STATIC
   Rand% = RND * (Hi - Lo) + Lo
END FUNCTION

