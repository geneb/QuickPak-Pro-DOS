'********** DAYNAME.BAS - shows how DayName works

DEFINT A-Z
DECLARE FUNCTION DayName$ (X%)

CLS
FOR X = 1 TO 7
    PRINT X; DayName$(X)
NEXT

