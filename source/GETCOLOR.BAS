'********** GETCOLOR.BAS - set of color functions

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z
DECLARE SUB GetColor (FG, BG)           'gets BASIC's current colors
DECLARE SUB SplitColor (XColor, FG, BG) '.ASM - splits a color into FG and BG
DECLARE FUNCTION OneColor% (FG, BG)     '.ASM - combines FG/BG into one color


CLS
INPUT "Enter a foreground color value (0 to 31): ", FG
INPUT "Enter a background color value (0 to 7) : ", BG
COLOR FG, BG

PRINT : PRINT "BASIC's current color settings are: ";
GetColor FG, BG
PRINT FG; "and"; BG

PRINT "That combines to the single byte value of"; OneColor%(FG, BG)
PRINT "Broken back out results in";
SplitColor OneColor%(FG, BG), NewFG, NewBG
PRINT NewFG; "and"; NewBG

COLOR 7, 0      'restore defaults before ending

'This function obtains BASIC's current colors by first saving the
'character and color in the upper left corner of the screen.  Next,
'a blank space is printed there, and SCREEN is used to see what color
'was used.  Finally, the original screen contents are restored.
'
SUB GetColor (FG%, BG%) STATIC
    V% = CSRLIN                         'save the current cursor location
    H% = POS(0)
    SaveChar% = SCREEN(1, 1)            'save the current character
    SaveColor% = SCREEN(1, 1, 1)        'and its color
    SplitColor SaveColor%, SaveFG%, SaveBG%

    LOCATE 1, 1                         'print with BASIC's current color
    PRINT " "; CHR$(29);                'back up the cursor to 1,1
    CurColor% = SCREEN(1, 1, 1)         'read the current color
    COLOR SaveFG%, SaveBG%              'restore the original color at 1,1
    PRINT CHR$(SaveChar%);              'and the character

    LOCATE V%, H%                       'put the cursor back where it was
    SplitColor CurColor%, FG%, BG%      'split the color into separate FG & BG
    COLOR FG%, BG%                      'restore BASIC's current value for it
END SUB

