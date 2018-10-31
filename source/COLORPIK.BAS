'******* COLORPIK.BAS - demos the assembler ColorPick and MColorPick routines

'Copyright (c) 1989 Crescent Software

DEFINT A-Z

CLS
BoxColor = 113          'the color of the surrounding box
Colr = 1                'start by highlighting color 1
LOCATE 2, 20, 0
CALL MColorPick(Colr, BoxColor, ExitCode)

LOCATE 22, 1
IF ExitCode = 0 THEN
   PRINT "You picked color"; Colr
ELSE
   PRINT "You pressed Escape"
END IF

