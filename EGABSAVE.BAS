'EGABSave.Bas - demonstrates saving and restoring an EGA/VGA screen on disk

DEFINT A-Z
DECLARE SUB EgaBSave (FileName$)
DECLARE SUB EgaBLoad (FileName$)

SCREEN 9
LOCATE 25, 1
PRINT "Press a key to stop the show, and save the screen to disk.";

WHILE INKEY$ = ""
    T = (T MOD 150) + 1
    C = (C + 1) MOD 16
    LINE (T, T)-(300 - T, 300 - T), C, B
    LINE (300 + T, T)-(600 - T, 300 - T), C, B
WEND

LOCATE 25, 1
PRINT "Thank You!"; TAB(75);
CALL EgaBSave("Test")

CLS
LOCATE 25, 1
PRINT "Now press a key to read the screen back in from disk.";
WHILE INKEY$ = "": WEND
LOCATE 25, 1
PRINT TAB(75);

CALL EgaBLoad("Test")

SUB EgaBLoad (FileName$) STATIC

    Fi$ = FileName$
    Ext = INSTR(Fi$, ".")
    IF Ext THEN Fi$ = LEFT$(Fi$, Ext - 1)

    'UnREM the Kill statements to erase the saved images after they're loaded

    DEF SEG = &HA000
    OUT &H3C4, 2: OUT &H3C5, 1: BLOAD Fi$ + ".BLU", 0
    'Kill Fi$ + ".BLU"
    OUT &H3C4, 2: OUT &H3C5, 2: BLOAD Fi$ + ".GRN", 0
    'Kill Fi$ + ".GRN"
    OUT &H3C4, 2: OUT &H3C5, 4: BLOAD Fi$ + ".RED", 0
    'Kill Fi$ + ".RED"
    OUT &H3C4, 2: OUT &H3C5, 8: BLOAD Fi$ + ".INT", 0
    'Kill Fi$ + ".INT"
    OUT &H3C4, 2: OUT &H3C5, 15

END SUB

SUB EgaBSave (FileName$) STATIC

    Fi$ = FileName$
    Ext = INSTR(Fi$, ".")
    IF Ext THEN Fi$ = LEFT$(Fi$, Ext - 1)

    DEF SEG = &HA000
    Size& = 28000               'use 38400 for VGA hi-res
    
    OUT &H3CE, 4: OUT &H3CF, 0: BSAVE Fi$ + ".BLU", 0, Size&
    OUT &H3CE, 4: OUT &H3CF, 1: BSAVE Fi$ + ".GRN", 0, Size&
    OUT &H3CE, 4: OUT &H3CF, 2: BSAVE Fi$ + ".RED", 0, Size&
    OUT &H3CE, 4: OUT &H3CF, 3: BSAVE Fi$ + ".INT", 0, Size&
    OUT &H3CE, 4: OUT &H3CF, 0

END SUB

