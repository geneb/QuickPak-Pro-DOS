'********* ASCCHART.BAS - ASCII pop-up display module

'Copyright (c) 1988 Paul Passarelli
'Copyright (c) 1988 Crescent Software


DEFINT A-Z
DECLARE SUB ASCIIChart (Row, Column, Height)
DECLARE SUB APrint0 (BYVAL Address, NumElem, FirstChar, NumChar, Colr)
DECLARE SUB Box0 (ULRow, ULCol, LRRow, LRCol, Char, Colr)
DECLARE SUB ScrnSave0 (ULRow, ULCol, LRRow, LRCol, SEG Address)
DECLARE SUB ScrnRest0 (ULRow, ULCol, LRRow, LRCol, SEG Address)

SUB ASCIIChart (Row, Column, Lines)

  IF Lines < 2 THEN Lines = 2
  REDIM Array((Lines + 2) * 12)         'holds the underlying screen
  BoxColor = 78                         'colors - modify to suit
  TextColor = 79

  REDIM Array$(0 TO 255)                'array to hold the displayed text
  H$ = SPACE$(2)                        'reserve room for Hex stuff
  FOR X = 0 TO 255
    Array$(X) = SPACE$(10)
    MID$(Array$(X), 1 - (X < 10) - (X < 100)) = STR$(X)
    MID$(Array$(X), 6 - (X < 16)) = HEX$(X)
    MID$(Array$(X), 9) = CHR$(X)
  NEXT
 
  CursV = CSRLIN: CursH = POS(0)        'save cursor position
  IF Row = -1 THEN Row = CursV          'if either is -1, use the
  IF Column = -1 THEN Column = CursH    '  current cursor location

  CALL ScrnSave0(Row, Column, Row + Lines + 1, Column + 11, Array(0))
  CALL Box0(Row, Column, Row + Lines + 1, Column + 11, 2, BoxColor)

  LOCATE Row + 1, Column + 1
  Block = Lines                         'set up to jump into code
  GOTO ASCIIPaul

DO
  Flag = 1                              'flag to do wrap
  Block = Lines                         'portion to wrap
  LOCATE Row + 1, Column + 1            'reset each time a block is split

ASCIIFast:
  K$ = INKEY$
  IF K$ = CHR$(27) THEN                 'Escape
    CALL ScrnRest0(Row, Column, Row + Lines + 1, Column + 11, Array(0))
    LOCATE CursV, CursH
    ERASE Array
    EXIT SUB
  ELSEIF LEN(K$) = 2 THEN
    SELECT CASE ASC(RIGHT$(K$, 1))
      CASE 71                           'Home
        FirstL = 0
      CASE 72                           'Up Arrow
        FirstL = FirstL - 1
      CASE 73                           'PgUp
        FirstL = FirstL - Block
      CASE 79                           'End
        FirstL = 256 - Block
      CASE 80                           'Down Arrow
        FirstL = FirstL + 1
      CASE 81                           'PgDn
        FirstL = FirstL + Block
      CASE ELSE
        GOTO ASCIIFast
    END SELECT
  ELSE
    GOTO ASCIIFast                      'ignore any other keys
  END IF

  IF FirstL > 255 THEN
    FirstL = FirstL - 256               'wrap down
    Flag = 1
  ELSEIF FirstL < -Block THEN
    FirstL = FirstL + 256               'wrap up
    Flag = 1
  ELSEIF FirstL < 0 THEN                'wrap to 255
    CALL APrint0(VARPTR(Array$(FirstL + 256)), -FirstL, 1, 10, TextColor)
    LOCATE Row + 1 + Block - (Block + FirstL), Column + 1
    Block = Block + FirstL
    Flag = 0
  ELSEIF FirstL > 256 - Block THEN      'wrap to zero
    CALL APrint0(VARPTR(Array$(FirstL)), 256 - FirstL, 1, 10, TextColor)
    LOCATE Row + 1 + (256 - FirstL), Column + 1
    Block = Block - (256 - FirstL)
    Flag = 0
  END IF

  IF Flag THEN LOCATE Row + 1, Column + 1
  IF CSRLIN < Row + 1 + Lines THEN
ASCIIPaul:
    CALL APrint0(VARPTR(Array$(FirstL * Flag)), Block, 1, 10, TextColor)
  END IF

LOOP

END SUB

