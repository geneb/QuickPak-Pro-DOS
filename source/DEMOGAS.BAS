'********** DEMOGAS.BAS - shows GasGauge in use

'Copyright (c) 1992 Ethan Winer


DEFINT A-Z
DECLARE SUB GasGauge (Min, Max, Value, Wide, Colr)

CLS                             'start with a clean slate
Wide = 70                       'specify the gauge width including the border
Min = 1: Max = 100              'the upper/lower bounds, ANY integers okay
Colr = 79                       'the color
LOCATE 18, 5, 0                 'the upper left corner of the gauge display

FOR X = Min TO Max
  CALL GasGauge(Min, Max, X, Wide, Colr)
  CALL Pause(1)                 'pause so we can see it work
NEXT

