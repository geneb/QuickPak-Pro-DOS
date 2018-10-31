'******** MRANGEG.BAS - tests MouseRangeG or MouseRangeG1 (see note below)

DEFINT A-Z

DECLARE SUB InitMouse (There)
DECLARE SUB MouseRangeG (SEG Element AS ANY, NumEls, Row, Column, Button, Range)
DECLARE SUB MouseRangeG1 (SEG Element AS ANY, NumEls, Row, Column, Button, Range)
DECLARE SUB ShowCursor ()

TYPE Area
  Y1 AS INTEGER
  X1 AS INTEGER
  Y2 AS INTEGER
  X2 AS INTEGER
  RN AS INTEGER
END TYPE

SCREEN 9
CALL InitMouse(There)
IF NOT There THEN
  SCREEN 0
  PRINT "No mouse installed -- ending."
  END
END IF
CALL ShowCursor
LOCATE 20, 1
PRINT "Press button 1 in a colored box to see the action, press button 2 to end."

REDIM Array(1 TO 5) AS Area
Array(1).X1 = 0
Array(1).Y1 = 0
Array(1).X2 = 20
Array(1).Y2 = 20
Array(1).RN = -1

Array(2).X1 = 21
Array(2).Y1 = 0
Array(2).X2 = 40
Array(2).Y2 = 20
Array(2).RN = -1

Array(3).X1 = 41
Array(3).Y1 = 0
Array(3).X2 = 60
Array(3).Y2 = 20
Array(3).RN = -1

Array(4).X1 = 61
Array(4).Y1 = 0
Array(4).X2 = 80
Array(4).Y2 = 20
Array(4).RN = -1

Array(5).X1 = 81
Array(5).Y1 = 0
Array(5).X2 = 100
Array(5).Y2 = 20
Array(5).RN = -1

FOR i = 1 TO 5
  LINE (Array(i).X1, Array(i).Y1)-(Array(i).X2, Array(i).Y2), i, BF
NEXT

DO
  'to test the "1" version unREM the line below and REM out the next line
  'CALL MouseRangeG1(Array(1), 5, R, C, Button, RNum)
  CALL MouseRangeG(Array(1), 5, R, C, Button, RNum)
  LOCATE 10, 1
  PRINT R, C, Button, RNum
  IF Button > 1 THEN END
LOOP

