'********** GASGAUGE.BAS - subprogram displays a percent status indicator

'Copyright (c) 1992 Ethan Winer


DEFINT A-Z
DECLARE SUB GasGauge (Min, Max, Value, Wide, Colr)

SUB GasGauge (Min, Max, Value, Wide, Colr) STATIC

  Row = CSRLIN                          'retrieve the current cursor location
  Column = POS(0)                       'and draw a box there
  NewWide = Wide - 2                    'exclude the border dimensions
  CALL Box0(Row, Column, Row + 4, Column + Wide + 1, 1, Colr)
 
  Row = Row + 1                         'bump the row and column, because
  Column = Column + 1                   ' we're printing at the next ones
  IF LEN(Pad$) <> Wide THEN Pad$ = SPACE$(Wide) 'holds title, bars, legends
  Part! = (Value - Min + 1) / (Max - Min + 1)   'percent divided by 100
  LSET Pad$ = STR$(INT(Part! * 100)) + " percent completed:"
  CALL QPrintRC(Pad$, Row, Column, Colr)
 
  Row = Row + 1                         'the gauge itself is on the next line
  NumBlocks = Wide * Part!              'calculate the number of solid blocks
  NumShades = Wide - NumBlocks          'and then the number of shaded blocks
  LSET Pad$ = STRING$(NumBlocks, 219) + STRING$(NumShades, 176)
  CALL QPrintRC(Pad$, Row, Column, Colr)

  'This next block of code prints the lower and upper limits beneath the
  'progress bar at each end.  If you prefer to remove this code you should
  'also change the call to Box0 above to use Row + 3 instead of Row + 4.
  Row = Row + 1
  LSET Pad$ = LTRIM$(STR$(Min))
  Max$ = LTRIM$(STR$(Max))
  MaxLen = LEN(Max$)
  MID$(Pad$, Wide - MaxLen + 1) = Max$
  CALL QPrintRC(Pad$, Row, Column, Colr)

END SUB

