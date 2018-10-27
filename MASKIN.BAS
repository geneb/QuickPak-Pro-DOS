'********** MASKIN.BAS - Masked input routine

'Copyright (c) 1990 Crescent Software
'written by Jay Munro
'
' 04/25/1992 - added foreign language support ­

DEFINT A-Z
'
DECLARE SUB MaskIn (Mask$, Text$, MSKI AS ANY)
DECLARE FUNCTION QPMid$ (X$, Y, Z)
DECLARE FUNCTION QPRight$ (X$, X)
DECLARE FUNCTION ASCII% (X$)
DECLARE FUNCTION IsLower% (X)
DECLARE FUNCTION IsUpper% (X)
DECLARE FUNCTION IsMath% (X)
DECLARE FUNCTION IsNumber% (X)
DECLARE FUNCTION IsPunct% (X)

'Parameters are passed to routine through the MaskParms type array
'  Ky is the ASCII value of the last key pressed
'  Action is:
'        0 to work non polling, <ENTER> or <ESC> terminates
'        1 initializes and checks for a keystroke
'        2 initializes without waiting for keystroke
'        3 skips initialization and just gets input
'
'        Actions 1 & 2 are changed to action 3 on exit from MaskIn
'
'  MColr is the color of to use for the message portion of the mask string
'  FColr is the color of the field where input is received

TYPE MaskParms
  Ky AS INTEGER                 'last key stroke entered
  Action AS INTEGER             'action flag
  MColr AS INTEGER              'message color
  FColr AS INTEGER              'field color
END TYPE

DIM MSKI AS MaskParms

FUNCTION IsLower% (X)
' ---------- true if X = lower case or space
  IsLower% = (X > 96 AND X < 123 OR X = 32) OR INSTR("‚ƒ„…†ˆ‰Š‹Œ“”•–—˜ ¡¢£¤á", CHR$(X))
END FUNCTION

FUNCTION IsMath% (X)
' -------- true if X = + , - .
  IsMath% = (X > 42 AND X < 47)
END FUNCTION

FUNCTION IsNumber% (X)
' -------- true if X = numbers 0123456789
  IsNumber% = (X > 47 AND X < 58)
END FUNCTION

FUNCTION IsPunct% (X)
' -------- true if X = !"#$%'()*+,-./:;<=>?[\]^_`{|}~
  IsPunct% = (X > 32 AND X < 48) OR (X > 57 AND X < 80) OR (X > 90 AND X < 97) OR (X > 122 AND X < 127 OR INSTR("›œŸ­¨", CHR$(X)))
END FUNCTION

FUNCTION IsUpper% (X)
' -------- true if X = Caps or space
  IsUpper% = (X > 64 AND X < 91 OR X = 32 OR INSTR("Ž’™š¥", CHR$(X)))
END FUNCTION

'MaskIn subroutine
'
' The mask string is examined a character at a time. If the ASCII value
' of the current character is < 32 then input is polled.  If the value is
' greater than 32, it is assumed to be part of the message, is printed, and
' the cursor is moved to the next character for testing.  The variable
' LocDir (Locate Direction) is set to either -1 or 1 and is added to the
' current column for locating at the next character.  Backspace and right
' arrow will set it to -1 for backward movement, all other character set
' it to 1 for forward movement.
'
' The maximum length of the mask string is 80 characters when located at the
' start of the line, but will be less when started in from column 1.
'
' The Text$ variable must be set to the maximum characters expected from
' Mask$'s input fields, or it will truncate input.  For example, if Mask$
' contains a field of 25 characters, Text$ must be set to 25 characters.
'
'
SUB MaskIn (Mask$, Text$, MSKI AS MaskParms) STATIC

Table$ = "„Žš”™¤¥‚"                 'european characters used in Upper/lower table
IF MSKI.Action < 3 THEN               'initialize everything
  LOCATE , , 0
  MaxLen = LEN(Mask$)                 'get Len of Mask$
  TCol = POS(0)                       'save current cursor location
  TRow = CSRLIN
  IF MaxLen + TCol > 80 THEN EXIT SUB 'keep it fitting on one line
  CurCol = 1                          'initializes current column
  TempCol = CurCol                    '  temp position
  LocDir = CurCol                     '  direction for locates
  FOR X = 1 TO MaxLen                 'print field loop
    IF ASCII%(QPMid$(Mask$, X, 1)) < 32 THEN  'check mask character
                                      'print character from incoming field
      CALL QPrintRC(QPMid$(Text$, TempCol, 1), TRow, TCol + X - 1, MSKI.FColr)
      TempCol = TempCol + 1           ' point to next character
    ELSE                              ' print mask character
      CALL QPrintRC(QPMid$(Mask$, X, 1), TRow, TCol + X - 1, MSKI.MColr)
    END IF
  NEXT X
  MSKI.Ky = 0                         'initialize keypress variable
  IF MSKI.Action = 2 THEN             'if action 2 then just get out without
     MSKI.Action = 3                  '  bothering for a keypress
     EXIT SUB
  END IF
  IF MSKI.Action > 0 THEN MSKI.Action = 3  'set action to stay in loop
END IF

' -------- MaskIn 'engine'
DO                                    'do/loop for Action flag = 0
  DO                                  'do/loop for key input
    MskChar = ASCII%(QPMid$(Mask$, CurCol, 1))  'get a char from Mask$
    IF MskChar < 32 THEN              'check mask character--input needed?
      LOCATE , , 1                    ' yes, turn on cursor
      DO                              ' do loop for inkey$
        A$ = INKEY$                   ' assign incoming character to A$
        Length = LEN(A$)              ' get length of character
      LOOP UNTIL Length OR MSKI.Action ' loop until a character is hit or in polled mode

      IF Length THEN                  ' if character is received
        IF Length = 2 THEN            ' check if it's an extended character
          MSKI.Ky = -ASCII%(QPRight$(A$, 1)) ' make it negative ASCII value
        ELSE                          ' otherwise just get ASCII value
          MSKI.Ky = ASCII%(A$)
        END IF
      ELSE
        EXIT DO                       ' no character, bag out
      END IF

      IF MSKI.Ky < 0 THEN             'check for extended key
        SELECT CASE MSKI.Ky           ' See what it is
          CASE -83                    'delete key
            CALL QPrintRC(" ", TRow, TCol + CurCol - 1, -1) ' print a space
          CASE -75                    'left arrow
            LocDir = -1               ' point direction backwards
            GOSUB CurPosition         ' and move cursor back one space
          CASE -77                    'right arrow
            LocDir = 1                ' point direction forwards
            GOSUB CurPosition         ' and move cursor forward one space
          CASE -72, -80, -15          'up,down, shift tab
            GOSUB GetTxt              ' load up string and exit
            EXIT DO
          CASE ELSE
        END SELECT

      ELSEIF MSKI.Ky > 0 THEN         'if any other character pressed
        SELECT CASE MSKI.Ky           '
          CASE 27                     'escape pressed
            EXIT SUB                  ' exit with MSKI.Ky = 27
          CASE 9, 13                  'carriage return
            GOSUB GetTxt              'get text and exit
            EXIT DO
          CASE 8                      'back space
            LocDir = -1               'point backwards
            Temp = CurCol             'assign a temporary cursor column
            DO
              Temp = Temp + LocDir    'subtract one from CurCol
              IF Temp > 1 AND Temp < MaxLen THEN   'if temp is within string area
                IF ASCII%(QPMid$(Mask$, Temp, 1)) < 32 THEN 'then check for mask char
                  GOSUB CurPosition                         ' update cursor if it is
                  CALL QPrintRC(" ", TRow, TCol + CurCol - 1, -1) ' print a space
                  EXIT DO                                   ' exit
                ELSE                                        'assign temp to CurCol
                  CurCol = Temp                             'to skip over non-input characters
                END IF
              ELSE                                          'CurCol is outside string
                EXIT DO                                     '  don't move any more
              END IF
            LOOP
          CASE ELSE
            LocDir = 1                                     'point forward
            IF MskChar THEN                                '
              DO UNTIL Flag

' -------- if accepting upper and lower, don't force anything
                IF (MskChar AND 3) = 3 THEN         'allow upper and lower case?
                  IF IsLower%(MSKI.Ky) OR IsUpper%(MSKI.Ky) THEN
                    Flag = -1
                    EXIT DO
                  END IF
                END IF

' -------- if uppercase only, force uppercase on lowercase letters
                IF MskChar AND 1 THEN         'allow upper case?
                  IF IsLower%(MSKI.Ky) OR IsUpper%(MSKI.Ky) THEN
                    CALL Upper(A$)
                    
                    CALL UpperTbl(A$, Table$)
                    Flag = -1
                    EXIT DO
                  END IF
                END IF

' -------- if lowercase only, force lowercase on uppercase letters
                IF MskChar AND 2 THEN         'allow lower case only?
                  IF IsLower%(MSKI.Ky) OR IsUpper%(MSKI.Ky) THEN
                    CALL Lower(A$)

                    CALL LowerTbl(A$, Table$)
                    Flag = -1
                    EXIT DO
                  END IF
                END IF

' -------- check individual flags
                IF Flag THEN EXIT DO
                IF MskChar AND 4 THEN Flag = IsNumber%(MSKI.Ky)'allow numbers?
                IF Flag THEN EXIT DO
                IF MskChar AND 8 THEN Flag = IsMath%(MSKI.Ky)  'allow periods, commas - + ?
                IF Flag THEN EXIT DO
                IF MskChar AND 16 THEN Flag = IsPunct%(MSKI.Ky)'allow full punctuation?
                EXIT DO
              LOOP

' -------- if we got a valid character, show it, otherwise beep!
              IF Flag THEN
                Flag = 0
                GOSUB PrintChar
              ELSE
                'BEEP                   'uREM this to actually BEEP
              END IF
            ELSE
              LOCATE , , 0                      'turn cursor off to skip over mask
              GOSUB CurPosition                 'move the cursor
            END IF
        END SELECT
      END IF
    ELSE
      LOCATE , , 0                      'turn cursor off to skip over mask
      GOSUB CurPosition                 'move the cursor
    END IF
  LOOP
LOOP UNTIL MSKI.Action OR MSKI.Ky <> 13 OR MSKI.Ky <> 27 OR MSKI.Ky < 0

EXIT SUB

' -------- entry point to print and move cursor
PrintChar:                              'print a character
  CALL QPrintRC(A$, TRow, TCol + CurCol - 1, -1)

' -------- entry point to just move cursor
CurPosition:
  CurCol = CurCol + LocDir              'update current cursor position
DO
  IF CurCol > MaxLen THEN               'right arrowed too far
     CurCol = MaxLen                    ' leave cursor at end
     EXIT DO
  ELSEIF CurCol < 1 THEN                'left arrowed to far
     CurCol = 1                         ' leave cursor at beginning
     LocDir = 1
     EXIT DO
  END IF
  LOCATE , TCol + CurCol - 1            'relocate the cursor
  EXIT DO
LOOP

RETURN

' -------- return typed info by reading characters from screen

GetTxt:
    Y = 1
    TLen = LEN(Text$)
    X$ = " "
    FOR X = 1 TO MaxLen
      IF ASCII%(QPMid$(Mask$, X, 1)) < 32 THEN
        CALL ReadScrn0(TRow, TCol + X - 1, X$)
        IF Y <= TLen THEN
          MID$(Text$, Y, 1) = X$
          Y = Y + 1
        ELSE
          EXIT FOR
        END IF
      END IF
    NEXT X
RETURN
END SUB

