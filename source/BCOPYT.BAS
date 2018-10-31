'******** BCOPYT.BAS - demonstrates copying TYPE elements around in memory

'Copyright (c) 1989 Ethan Winer


DEFINT A-Z
DECLARE SUB BCopyT (SEG FromEl AS ANY, SEG ToEl AS ANY, ElSize, NumEls)

TYPE Test
  L AS LONG
END TYPE

CLS
REDIM FromArray(1 TO 20000) AS Test
REDIM DestArray(1 TO 20000) AS Test

FOR X = 16301 TO 17000          'this range proves that BCopyT successfully
  FromArray(X).L = X            '  accommodates a segment division
NEXT

CALL BCopyT(FromArray(16301), DestArray(16301), -2, 700)

FOR X = 16300 TO 17001          '***** elements 16300 and 17001 SHOULD fail
  IF DestArray(X).L <> X THEN
    PRINT "DestArray"; X; "="; DestArray(X).L
    CALL Chime(9)
  END IF
NEXT

