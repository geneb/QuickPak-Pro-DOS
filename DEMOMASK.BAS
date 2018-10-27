'*********** DEMOMASK.BAS - demonstrates the MaskIn BASIC input routine

'Copyright (c) 1990 Crescent Software
'Written by Jay Munro


'Table of mask characters
'    Bits 1 to 5 are flags for these types of characters
'                                    Binary    Dec   Character
'                                    ======    ===   =========
'      Caps Alpha only               00001b     1        
'      Lower Alpha only              00010b     2        
'      Numbers                       00100b     4        
'      Periods,commas,-+             01000b     8        
'      Full punctuation              10000b    16        
'
'    Combining bits gives more choices:
'
'      Wild card                     11111b    31        
'      Caps and lower alpha          00011b     3        
'      Caps with numbers             00101b     5        
'      Letters-numbers               00111b     7        
'      Caps with periods, commas -+  01001b     9     (undisplayable in QB)
'      Lowercase with periods        01010b    10     (undisplayable in QB)
'      Caps, Lower with -+,.         01011b    11        
'      Numbers, periods, commas, -+  01100b    12        
'      Caps, numbers with -+,.       01101b    13     (undisplayable in QB)
'      Lowercase,numbers,-+.,        01110b    14        
'      Caps, Lower,numbers,-+.,      01111b    15        
'      Caps, full punctuation        10001b    17        
'      Lowercase, full punctuation   10010b    18        
'      Caps, Lower, full punctuation 10011b    19        
'      Numbers, full punctuation     10100b    20        
'      Caps, numbers, punctuation    10101b    21        
'      Lower, numbers, punctuation   10110b    22        
'      Caps, lower, numbers, punct   10111b    23        
'
'      Anything with both bit 4 and bit 5 set would be redundant.
'
'Characters that can't be displayed can be created with STRING$(N, X)
'where N is the number of characters and X is the ASCII value.


DEFINT A-Z
DECLARE SUB MaskIn (Mask$, Text$, Msk AS ANY)

'--------- Type defines colors, action and returns last key pressed

TYPE MaskParms
  Ky AS INTEGER                 'Last key stroke entered
  Action AS INTEGER             'Action flag
  MColr AS INTEGER              'Message color
  FColr AS INTEGER              'Field color
END TYPE

DIM Msk AS MaskParms            'Control array MSK
Msk.MColr = 7                   'Mask color
Msk.FColr = 112                 'Field color
Msk.Action = 0                  'Action 0 to start

CLS

' -------- Start by showing what each bit allows

CALL QPrintRC("Here are the basic building blocks of MaskIn", 1, 5, Msk.MColr)

' -------- Caps only bit 1 -- CHR$(1)
Mask$ = "This is Caps Only " + STRING$(10, 1)
Info$ = SPACE$(10)
LOCATE 3, 5
CALL MaskIn(Mask$, Info$, Msk)
GOSUB PrintInfo

' -------- Lowercase only bit 2 -- CHR$(2)
Mask$ = "This is lowercase Only " + STRING$(10, 2)
Info$ = SPACE$(10)
LOCATE , 5
CALL MaskIn(Mask$, Info$, Msk)
GOSUB PrintInfo

' -------- Numbers only bit 3 -- CHR$(4)
Mask$ = "This is numbers Only "
Info$ = SPACE$(10)
LOCATE , 5
CALL MaskIn(Mask$, Info$, Msk)
GOSUB PrintInfo

' -------- Numbers only bit 4 -- CHR$(8)
Mask$ = "This is periods, commas and -+ Only "
Info$ = SPACE$(10)
LOCATE , 5
CALL MaskIn(Mask$, Info$, Msk)
GOSUB PrintInfo

' -------- Punctuation only bit 5 -- CHR$(16)
Mask$ = "This is full punctuation Only "
Info$ = SPACE$(10)
LOCATE , 5
CALL MaskIn(Mask$, Info$, Msk)
GOSUB PrintInfo

' -------- Show multiple masks in the same string
Mask$ = "Name   Rank   Serial Number --"
Info$ = "John Smith      2 MUCH  111223333"
LOCATE CSRLIN + 2, 5
PRINT "You can enter different input from the same mask string"
LOCATE , 5
CALL MaskIn(Mask$, Info$, Msk)
LOCATE CSRLIN + 1, 5
PRINT Info$

' -------- First print just the fields by setting the action to 2

CALL QPrintRC("Now something useful for a change...Press ESC to end", 14, 1, Msk.MColr)
DIM DArray$(6)                          'set up some variables
FOR X = 1 TO 6
   READ DArray$(X)
   READ Mask$(X)
   READ R(X), C(X)
   Msk.Action = 2                       'just initialize
   LOCATE R(X), C(X)                    'locate field
   CALL MaskIn(Mask$(X), DArray$(X), Msk)
NEXT X

' -------- Now go back with an action 1 and loop for input

I = 1                                   'field counter
DO
  Msk.Action = 1                        'action of 1 initializes and loops
  LOCATE R(I), C(I)                     'locate field
  DO                                    'input loop
    CALL MaskIn(Mask$(I), DArray$(I), Msk)
 
  SELECT CASE Msk.Ky
    CASE 9, 13, -80                     'tab, enter, down arrow
      I = I + 1                         'increment the field
      IF I > 6 THEN I = 1
      EXIT DO
    CASE 27                             'escape key
      EXIT DO
    CASE -15, -72                       'shift tab, up arrow
      I = I - 1
      IF I < 1 THEN I = 6
      EXIT DO
    CASE ELSE
  END SELECT
  LOOP
  IF Msk.Ky = 27 THEN EXIT DO           'loop until escape is pressed
LOOP

FOR I = 1 TO 6                          'print the results
  LOCATE R(I) + 5, C(I)
  PRINT DArray$(I);
NEXT I

END

' -------- demo field input data

DATA   "Bugs             "                      : 'default field string
DATA   "First name: "          : 'mask string
DATA   16,5                                     : 'location on screen

DATA   "Bunny            "
DATA   " Last name: "
DATA   17,5

DATA   "1105 Carrot Road        "
DATA   "Street: "
DATA   18,5

DATA   "Hollywood      "
DATA   "City: "
DATA   19, 5

DATA   "CA"
DATA   "State: "
DATA   19,26


DATA   "12345"
DATA   "Zip:"
DATA   19,37
         
' -------- routine to print info on right of screen
PrintInfo:                           
  LOCATE , 60
  PRINT Info$
RETURN

