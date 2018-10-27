'********** Time.Bas - demonstrates Time2Num and Num2Time

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z
DECLARE FUNCTION Time2Num& (T$)
DECLARE FUNCTION Num2Time$ (Number&)

CLS
INPUT "Enter a time in the form HH:MM:SS (or HHMMSS): ", T1$
INPUT "                           Enter another time: ", T2$
PRINT

IF (LEN(T1$) <> 6 AND LEN(T1$) <> 8) OR (LEN(T2$) <> 6 AND LEN(T2$) <> 8) THEN
   PLAY "L32O3ECECEC"
   PRINT "Please enter the numbers as shown - press any key ";
   WHILE INKEY$ = "": WEND
   RUN
END IF

Number1& = Time2Num&(T1$)
Number2& = Time2Num&(T2$)
PRINT T1$; " - "; T2$; " = "; Number1& - Number2&
PRINT T1$; " + "; T2$; " = "; Number1& + Number2&

PRINT
PRINT T1$; " - "; T2$; " = "; Num2Time$(Number1& - Number2&)
PRINT T1$; " + "; T2$; " = "; Num2Time$(Number1& + Number2&)

