'********** Shift.Bas -  demos the various QuickPak bit shifting commands

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z

DECLARE FUNCTION Int2Bin$ (Number)      'converts an int to a Binary string
DECLARE FUNCTION Long2Bin$ (Number&)    'converts a long to a Binary string
DECLARE SUB ShiftIL (Value, NumBits)    'shifts an integer NumBits left
DECLARE SUB ShiftIR (Value, NumBits)    'shifts an integer NumBits right
DECLARE SUB ShiftLL (Value&, NumBits)   'shifts a long integer NumBits left
DECLARE SUB ShiftLR (Value&, NumBits)   'shifts a long integer NumBits right


CLS

INPUT "Enter a number ", X$
IF X$ = "" THEN END
INPUT "How many bits? ", NumBits
PRINT

LongInt& = VAL(X$)
IF LongInt& < 32768 AND LongInt& > -32769 THEN
   Temp = LongInt&
   PRINT "Before shifting: "; Int2Bin$(Temp)
   ShiftIL Temp, NumBits
   PRINT "   Shifted left: "; Int2Bin$(Temp)
   PRINT
   Temp = LongInt&
   PRINT "Before shifting: "; Int2Bin$(Temp)
   ShiftIR Temp, NumBits
   PRINT "  Shifted right: "; Int2Bin$(Temp)
ELSE
   Temp& = LongInt&
   PRINT "Before shifting: "; Long2Bin$(Temp&)
   ShiftLL Temp&, NumBits
   PRINT "   Shifted left: "; Long2Bin$(Temp&)
   PRINT
   Temp& = LongInt&
   PRINT "Before shifting: "; Long2Bin$(Temp&)
   ShiftLR Temp&, NumBits
   PRINT "  Shifted right: "; Long2Bin$(Temp&)
END IF

FUNCTION Int2Bin$ (Number%)     'converts an integer to a Binary string
    Binary$ = STRING$(16, "0")
    FOR X% = 1 TO 16
        IF Number% AND 2 ^ (X% - 1) THEN MID$(Binary$, 17 - X%) = "1"
    NEXT
    Int2Bin$ = Binary$
END FUNCTION

FUNCTION Long2Bin$ (Number&)      'converts a long integer to a Binary string
    Binary$ = STRING$(32, "0")
    FOR X% = 1 TO 31
        IF Number& AND CSNG(2! ^ (CSNG(X%) - 1)) THEN
           MID$(Binary$, 33 - X%) = "1"
        END IF
    NEXT
    IF Number& < 0 THEN MID$(Binary$, 1, 1) = "1"
    Long2Bin$ = Binary$
END FUNCTION

