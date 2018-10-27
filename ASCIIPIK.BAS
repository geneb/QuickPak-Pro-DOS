'********** ASCIIPIK.BAS - demos ASCIIPick

'Copyright (c) 1988 Crescent Software


DEFINT A-Z
CLS
CALL InitMouse(X)
CALL TextCursor(112, 0)
CALL ShowCursor

X = 65                  'start by highlighting "A"
NormColr = 2            'use a green color
HiColor = 112 + 128     'use flashing inverse for the selected character
LOCATE 2, 3

'----- going in, if ExitCode = -1, then just display the chart and return
CALL MASCIIPick(X, NormColr, HiColor, ExitCode)
'----- coming out, ExitCode = 0 if Enter, or 2 if Escape (Escape also ignores)

LOCATE 21, 1
PRINT "You picked character"; X
IF ExitCode = 2 THEN PRINT "You pressed Escape";

