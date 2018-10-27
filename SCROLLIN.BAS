'******** SCROLLIN.BAS - scrollable input line editor subroutine

'Copyright (c) 1991 Crescent Software
'Written by Phil Cramer


DEFINT A-Z

DECLARE SUB QPRintRC (A$, Row, Col, Clr)
DECLARE SUB GetCursorT (Row, Col, Button)
DECLARE SUB WaitUp ()
DECLARE SUB HideCursor ()
DECLARE SUB ShowCursor ()

DECLARE FUNCTION PDQTimer& ()
DECLARE FUNCTION QInstr2% (StartPos, Filter$, Ky$)
DECLARE SUB Upper (A$)

CONST Filter1$ = "1234567890- "         'Mask for Integers ONLY
CONST Filter2$ = "1234567890.^ed+-/ "   'Mask for Single/Double precision ONLY
CONST Filter3$ = ""                     'User definable Mask

'ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
'³  ScrollIn arguments:                                                      ³
'³                                                                           ³
'³  Edit$   The string to be edited. May be any length                       ³
'³                                                                           ³
'³  Start   On entry Start is the first character to be displayed in the edit³
'³          window. On exit, Start holds the column where the cursor was last³
'³                                                                           ³
'³  Wide    The width of the edit window                                     ³
'³                                                                           ³
'³  MaxLen  The maximum allowable length of Edit$. If MaxLen = Wide then no  ³
'³          scrolling will occur                                             ³
'³                                                                           ³
'³  Filter  Determines the type of text to be entered and may be set to the  ³
'³          any of the following numbers:                                    ³
'³                                                                           ³
'³            0  All regular keys will be accepted                           ³
'³            1  Integers characters only                                    ³
'³            2  Integer, Single or Double precision characters only         ³
'³            3  User defined                                                ³
'³            4  Converts all letters to upper case                          ³
'³                                                                           ³
'³  Ky      On entry Ky is the column at which to place the cursor. On exit  ³
'³          Ky returns the key used to Exit ScrollIn.BAS                     ³ 
'³                                                                           ³
'³  EdClr   The color to use while editing  (See COLORS.BAS)                 ³
'³                                                                           ³
'³  NormClr The color to use when editing is complete  (See COLORS.BAS)      ³
'³                                                                           ³
'ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
'
SUB ScrollIn (Edit$, Start, Wide, MaxLen, Filter, Ky, EdClr, NormClr) STATIC

  InsertOn = 0
  Row = CSRLIN                            'Get the Edit row
  Col = POS(0)                            'Get the Edit Column
  OS = Col                                'Calculate the offset from Column 1
  LCol = Col                              'Left side of window
  RCol = LCol + Wide - 1                  'Right side of window

  Ed$ = SPACE$(MaxLen)                    'Dim the string
  LSET Ed$ = Edit$                        'Place the Edit$ in the Field
  Clr = EdClr                             'Start with Edit Color
  GOSUB PrintIt                           'Print The string

  LOCATE , , 1, 6, 7                      'Turn on the cursor
  Col = Col + Ky - 1                      'Find the cursor column

  'Start + Col - OS = The current character position in the string

  DO
    Ky$ = INKEY$                          'Get the KeyPress

    SELECT CASE LEN(Ky$)
      CASE 0
        Ky = 0
      CASE 1                              'Regular key
        Ky = ASC(Ky$)
      CASE 2
        Ky = -ASC(RIGHT$(Ky$, 1))         'Extended key, convert to negative
      CASE ELSE
    END SELECT

    'MMMMMMMMMMMMMMMMMMMMMM Start of Mouse Code MMMMMMMMMMMMMMMMMMMMMMMM
    'M   If you do not require a mouse, eliminate the code from here   M
    'M   to the next block of 'MMMMMM statements                       M
    'MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

    CALL GetCursorT(MCol, MRow, Button)

    IF Button = 1 THEN                        'If they left clicked
                                              'If we clicked on the field,
                                              ' find new cursor position
      IF MRow = Row AND MCol >= LCol AND MCol <= RCol THEN
        HideCursor                            'Turn Mouse cursor Off
        Col = MCol
                                                
        IF NOT Pressed THEN                   'Set the timer if first time
          T& = PDQTimer&
        ELSE
          IF PDQTimer& - T& > 2 THEN Time = -1'Wait 2 ticks before we scroll
        END IF
          
        IF MCol = RCol AND Time THEN          'If we're holding down the
          Col = Col + 1                       ' mouse button on the far
          X = 1                               ' right column, scroll right
        END IF

        IF MCol = LCol AND Time THEN          'If we're holding down the
          Col = Col - 1                       ' mouse button on the far
          X = 1                               ' left button, scroll left
        END IF
        Pressed = -1                          'Set the Button pressed flag

      ELSE                                    'They pressed outside the window
        CALL WaitUp                           'Wait til they release the key
        MPressed = -1                         'Set flag
        Ky = 13                               'Make like Enter pressed

      END IF

    ELSE
      Pressed = 0                             'Reset Flags
      Time = 0
      ShowCursor                              'Turn Mouse Cursor On

    END IF

    'MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
    'M                        End of Mouse Code                       M
    'MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

    SELECT CASE Ky
      CASE 0

      '---- BackSpace
      CASE 8
        IF Start + Col - OS > 1 THEN
          IF InsertOn THEN
            MID$(Ed$, Start + Col - OS - 1) = MID$(Ed$, Start + Col - OS) + " "
          ELSE
            MID$(Ed$, Start + Col - OS + (Start <> 0), 1) = " "
          END IF
          Col = Col - 1
          GOSUB PrintIt
          X = 1
        END IF

      '----Tab                        'Move forward 8 spaces at a time
      CASE 9
        Col = Col + 8
        X = 8

      '----Escape
      CASE 27
        Clr = NormClr
        LSET Ed$ = Edit$              'Return un-edited string
        GOSUB PrintIt
        Ed$ = ""                      'Clear the copy
        EXIT SUB                      'Outta' here

      '----Shift Tab                  'Move backward 8 spaces at a time
      CASE -15
        Col = Col - 8
        X = 8

      '----Alt R
      CASE -19                        'Restore original field
        LSET Ed$ = Edit$
        GOSUB PrintIt

      '----Alt C                      'Clear the field
      CASE -46
        Ed$ = SPACE$(MaxLen)
        GOSUB PrintIt

      '---- Left Arrow
      CASE -75
        Col = Col - 1
         X = 1

      '----Right Arrow
      CASE -77
        Col = Col + 1
        X = 1

      '----Home
      CASE -71
        Start = 1
        Col = -1
        X = 1

      '----  Up, PgUp, Down, PgDown, Enter
      CASE -72, -73, -80, -81, 13
        Clr = NormClr
        Edit$ = Ed$
        GOSUB PrintIt
        Ed$ = ""
        IF MPressed THEN Ky = 1000    'Return code for mouse click
        Start = Col - OS + 1          'Return the current cursor column
        EXIT SUB

      '----End
      CASE -79
        FOR i = MaxLen TO 1 STEP -1   'Find last character in the string
          IF MID$(Ed$, i, 1) <> " " THEN
            Start = i - Wide
            EXIT FOR
          END IF
        NEXT

        IF i > Wide THEN              'Not found in the current window
          Col = RCol + 1              'Scroll right
          X = 1
        ELSE                          'Found in the current window
          Start = 1
          Col = i + OS
        END IF

      '----Ins                        'Toggle Insert Status
      CASE -82
        InsertOn = NOT InsertOn
        IF InsertOn THEN
          LOCATE , , , 0, 7           'Insert OFF, use small cursor
        ELSE
          LOCATE , , , 6, 7
        END IF                        'Insert ON use full cursor

      '----Delete                     'Remove a character
      CASE -83
        MID$(Ed$, Start + Col - OS) = MID$(Ed$, Start + Col - OS + 1) + " "
        GOSUB PrintIt

      '----Control Right              'Move Wide spaces -1 to the right
      CASE -116
        Col = Col + Wide - 1
        X = Wide - 1

      '----Control Left               'Move Wide spaces +1 to the left
      CASE -115
        Col = Col - Wide + 1
        X = Wide + 1

      '----All normal keys            'Handle regular keys
      CASE 32 TO 255
        Found = -1
        SELECT CASE Filter
          CASE 1                      'Integers Only
            IF QInstr2%(1, Filter1$, Ky$) = 0 THEN Found = 0
          CASE 2                      'Single/Double precision Numbers only
            IF QInstr2%(1, Filter2$, Ky$) = 0 THEN Found = 0
          CASE 3                      'User defined
            IF QInstr2%(1, Filter3$, Ky$) = 0 THEN Found = 0
          CASE 4
            CALL Upper(Ky$)
          CASE ELSE
        END SELECT

        IF Found THEN                 'If its an acceptable key
          IF InsertOn THEN
            MID$(Ed$, Start + Col - OS) = Ky$ + MID$(Ed$, Start + Col - OS)
            Col = Col + 1
            GOSUB PrintIt
          ELSE
            MID$(Ed$, Start + Col - OS, 1) = Ky$
            GOSUB PrintIt
            Col = Col + 1
          END IF
        END IF
        X = 1
      CASE ELSE
    END SELECT

    IF Col > RCol THEN               'Make sure we stay within the field
      Col = RCol
      Start = Start + X
      GOSUB PrintIt
    ELSEIF Col < LCol THEN
      Col = LCol
      Start = Start - X
      GOSUB PrintIt
    END IF
    LOCATE Row, Col                   'Locate the Cursor

  LOOP

PrintIt:
  IF MaxLen - Start + 1 < Wide THEN Start = MaxLen - Wide + 1 'Make sure
  IF Start < 1 THEN Start = 1                               ' we stay in range
  HideCursor
  QPRintRC MID$(Ed$, Start, Wide), Row, LCol, Clr         'Print the string
  ShowCursor
RETURN

END SUB

