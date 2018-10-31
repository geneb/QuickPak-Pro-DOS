'********** DEMOEVAL.BAS - evaluates an equation to a double precision value

'Copyright (c) 1988 Crescent Software, Inc.
'Written by Paul Passarelli
'Revised 06/28/90


DEFINT A-Z
DECLARE FUNCTION Evaluate# (Equation$)

'NOTE: This routine understands the constant "e", therefore for exponential
'      notation be sure to use a capital "E" or "D".


LOCATE , , 1
CONST NumSamples = 20
DIM Sample$(NumSamples)

DO
   CLS
   RESTORE
   FOR X = 1 TO NumSamples
       READ Sample$(X)
       '----- we can't read quotes, so here's sample expression #12:
       IF X = 12 THEN Sample$(X) = CHR$(34) + "sample 1" + CHR$(34) + " = " + CHR$(34) + "SAMPLE 1" + CHR$(34)
       PRINT X; TAB(5); Sample$(X)
   NEXT

   PRINT
   LINE INPUT "Which expression, or press Enter to type one: ", X$
   IF X$ = "" THEN
      LINE INPUT "Enter the expression: ", X$
   ELSE
      X$ = Sample$(VAL(X$))
   END IF
   PRINT "That evaluates to: "; Evaluate#(X$);  'here's how you invoke it

   IF X$ = Sample$(14) THEN PRINT "00"

   IF LEFT$(X$, 1) = "%" THEN                   'see if there was an error
      BEEP
      PRINT "Error in formula or overflow"
   END IF

   PRINT TAB(60); "Do again? (Y/N) ";
   X$ = INPUT$(1)
  
   IF UCASE$(X$) = "N" THEN END

LOOP
  


'---- sample expressions for testing

DATA "(2 / 2.3E2) * 2E3 * 0"
DATA "-(1+SQR(((2*3+45-41)+(5+(3*5)))*((2*3)+(800+60+4-800-60-5)))^2)"
DATA "(2 + 3)!"
DATA "170! - 169!-168!-167!"
DATA "e ^ LOG(4 * ATN(1))"
DATA "(1890 - 1890)!"
DATA "1+(1-3)^2+2+2"
DATA "(((((((-5))-3)))))"
DATA "sqr(sqr64*sqr64)*sqr(sqr64*sqr64)"
DATA "(3 * 4^2 + 1) / 7"
DATA "-1 + 2 * 3 / 4^5"
DATA ""                              : 'this is assigned above
DATA "(2^2)^8"
DATA "SIN-.2048686209027326 00"
DATA "SQR(((100) ^ 2 + (-110) ^ 2 + (95) ^ 2 + (95) ^ 2) / 4)"
DATA "5000*(7/13200)^2"
DATA "68+160*.5*22E-6*25^2*60"
DATA "(-1)*(-2)*(-3)*+4"
DATA "(-3)*(-2)*(-1)"
DATA "(5 = 1 OR 10 < 1 OR 10 = 10) AND (-1 = NOT 0)"

