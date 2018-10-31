' **** EVALUATE.BAS - evaluates an equation to a double precision value

'Copyright (c) 1988 Crescent Software, Inc.
'Written by Paul Passarelli


DEFINT A-Z
DECLARE FUNCTION Evaluate# (Equation$)

'ASM Functions
DECLARE FUNCTION ASCII% (Strng$)
DECLARE FUNCTION Compact$ (Spaced$)
DECLARE FUNCTION Date2Num% (Dat$)
DECLARE FUNCTION Factorial# (ZeroTo170%)
DECLARE FUNCTION InCount% (Source$, Search$)
DECLARE FUNCTION MaxInt% (A, B)
DECLARE FUNCTION MinInt% (A, B)
DECLARE FUNCTION QInstrB% (Start, Text$, Search$)
DECLARE FUNCTION PMatch% (Work$)
DECLARE FUNCTION QPLen% (Strng$)

FUNCTION Evaluate# (Equation$)

'Copyright (c) 1988 Crescent Software
'Copyright (c) 1988 Paul Passarelli
'Revised 07/16/90

STATIC Again%, OP$(), OP%(), Logic$(), Constant$(), Constant%()
STATIC Functn%, Position%, LeftSide$, RightSide$, Term#, Term$, RTerm#, LTerm#
STATIC RTerm$, LTerm$, L%, Ticker%, PstnMult%, PstnDiv%, Pstn1%, Pstn2%, Pstn3%
STATIC Valid$, DE$, Digit$, Numeric$, Substitute%

Incoming$ = Compact$((Equation$))       'work with a copy to leave the
                                        'original alone

IF NOT Again% THEN              'do this initialization stuff only once for
   Again% = -1                  ' the entire program to save time

   '***** The structure for the Constant$ array is set up as follows:
   'The first subscript of the array holds the name as it is used in the
   'expression, and the second subscript holds the value to be inserted.
   '
   '** Important! The array Constant% holds the length of the name.  For
   'example "PI" is two characters, so Constant%(1) = 2.  Furthermore, any
   'constant that is a substring of another MUST follow it in the table.
   'See the OP$ & OP% assignments below.



   '***** Assign Constants ..................................................
   Count% = 3                   'how many constants are there
   DIM Constant$(Count%, 2)     'two dimensional array
   DIM Constant%(Count%)        'table of lengths
   Constant%(0) = Count%        'for use during replacements

   Constant$(1, 1) = "PI"
   Constant$(1, 2) = "3.14159265358979323846"
   Constant%(1) = 2

   Constant$(2, 1) = "e"
   Constant$(2, 2) = "2.71828182845904523536"
   Constant%(2) = 1

   Constant$(3, 1) = "@TODAY"
   Constant$(3, 2) = STR$(Date2Num%(DATE$))
   Constant%(3) = 6


   '***** Define Symbols for Functions .....................................
   DIM OP$(29): DIM OP%(29)

   OP$(1) = "ARCSINH": OP%(1) = 7       'contains "SIN"
   OP$(2) = "ARCCOSH": OP%(2) = 7
   OP$(3) = "ARCTANH": OP%(3) = 7
   OP$(4) = "ARCSECH": OP%(4) = 7
   OP$(5) = "ARCCSCH": OP%(5) = 7
   OP$(6) = "ARCCOTH": OP%(6) = 7
   OP$(7) = "ARCSIN": OP%(7) = 6
   OP$(8) = "ARCCOS": OP%(8) = 6
   OP$(9) = "ARCSEC": OP%(9) = 6
   OP$(10) = "ARCCSC": OP%(10) = 6
   OP$(11) = "ARCCOT": OP%(11) = 6
   OP$(12) = "SINH": OP%(12) = 4        'also contains "SIN"
   OP$(13) = "TANH": OP%(13) = 4
   OP$(14) = "SECH": OP%(14) = 4
   OP$(15) = "CSCH": OP%(15) = 4
   OP$(16) = "COTH": OP%(16) = 4
   OP$(17) = "SEC": OP%(17) = 3
   OP$(18) = "CSC": OP%(18) = 3
   OP$(19) = "COT": OP%(19) = 3
   OP$(20) = "SIN": OP%(20) = 3         'the real "SIN"
   OP$(21) = "COS": OP%(21) = 3
   OP$(22) = "TAN": OP%(22) = 3
   OP$(23) = "ATN": OP%(23) = 3
   OP$(24) = "LOG": OP%(24) = 3         'could become LN & 2  Natural Log
   OP$(25) = "EXP": OP%(25) = 3
   OP$(26) = "SQR": OP%(26) = 3
   OP$(27) = "CLG": OP%(27) = 3         'could become LOG & 3  Common Log
   OP$(28) = "ABS": OP%(28) = 3
   OP$(29) = "NOT": OP%(29) = 3

   DIM Logic$(2)
   Logic$(1) = "AND"
   Logic$(2) = "OR"
         
END IF  'Conclusion of the Static Part



'***** Replace Constants with Their Values ...................................
    FOR Substitute% = 1 TO Constant%(0)
        DO
           Position% = INSTR(Incoming$, Constant$(Substitute%, 1))
           'see if we are between quotes 04/23/90
           IF InCount%(LEFT$(Incoming$, Position), CHR$(34)) MOD 2 THEN Position = 0
           IF Position% THEN
              LeftSide$ = LEFT$(Incoming$, Position% - 1)
              RightSide$ = MID$(Incoming$, Position% + Constant%(Substitute%))
              Term$ = Constant$(Substitute%, 2)
              Incoming$ = LeftSide$ + Term$ + RightSide$
              LeftSide$ = "": Term$ = "": RightSide$ = ""
           ELSE
              EXIT DO
           END IF
        LOOP
    NEXT
    Incoming$ = UCASE$(Incoming$)
  


'***** Evaluate Parenthetical Expressions ....................................
'      make sure there are a matching number of left and right parentheses
    IF InCount%(Incoming$, "(") <> InCount%(Incoming$, ")") GOTO ErrorExit
    IF ASCII%(Incoming$) = 37 GOTO ErrorExit   'a "%" was added earlier, error
    DO
       Place% = INSTR(1 + Place%, Incoming$, "(")  'find the first open paren
       IF Place% THEN                              'there is one
          EndMrkr% = PMatch%(MID$(Incoming$, Place%))  'find the closing paren
          Isolated$ = MID$(Incoming$, Place% + 1, EndMrkr% - 2)  'isolate part
          Paren$ = LTRIM$(STR$(VAL(Isolated$)))
          IF (Isolated$ = Paren$) OR (Isolated$ = "+" + Paren$) THEN
             Incoming$ = LEFT$(Incoming$, Place% - 1) + Paren$ + MID$(Incoming$, Place% + EndMrkr%)
          ELSE
             IsoTerm# = Evaluate#(Isolated$)          'evaluate part
             Incoming$ = LEFT$(Incoming$, Place% - 1) + LTRIM$(STR$(IsoTerm#)) + MID$(Incoming$, Place% + EndMrkr%)
             IF ASCII%(Isolated$) = 37 GOTO ErrorExit
          END IF
       ELSE
          EXIT DO
       END IF
    LOOP
    Equat$ = LTRIM$(STR$(VAL(Incoming$)))
    IF (Incoming$ = Equat$) OR (Incoming$ = "+" + Equat$) GOTO Done
       
   
   
'***** Solve Trig. and other single operator functions .........................
    FOR Functn% = 1 TO UBOUND(OP%)
        DO
           Position% = INSTR(Incoming$, OP$(Functn%))
           IF Position% THEN
              LeftSide$ = LEFT$(Incoming$, Position% - 1)
              Position% = Position% + OP%(Functn%) - 1

              GOSUB TermBlockR
    
              SELECT CASE Functn%
                 
                CASE 1                  '"ARCSINH": OP%(1) = 7
                Term# = LOG(RTerm# + SQR(RTerm# * RTerm# + 1))
               
                CASE 2                  '"ARCCOSH": OP%(2) = 7
                Term# = LOG(RTerm# + SQR(RTerm# * RTerm# - 1))
               
                CASE 3                  '"ARCTANH": OP%(3) = 7
                Term# = LOG((1 + RTerm# / 1 - RTerm#)) / 2
               
                CASE 4                  '"ARCSECH": OP%(4) = 7
                Term# = LOG((SQR(-RTerm# * RTerm# + 1) + 1) / RTerm#)
               
                CASE 5                  '"ARCCSCH": OP%(5) = 7
                Term# = LOG((SGN(RTerm#) * SQR(RTerm# * RTerm# + 1) + 1) / RTerm#)
               
                CASE 6                  '"ARCCOTH": OP%(6) = 7
                Term# = LOG((RTerm# + 1) / (RTerm# - 1)) / 2
               
                CASE 7                  '"ARCSIN": OP%(7) = 6
                IF RTerm# = 1# THEN
                  Term# = 0#
                ELSE
                  Term# = ATN(RTerm# / SQR(-RTerm# * RTerm# + 1))
                END IF

                CASE 8                  '"ARCCOS": OP%(8) = 6
                Term# = -ATN(RTerm# / SQR(-RTerm# * RTerm# + 1)) + 1.57079637050629#    '07/16/90
               
                CASE 9                  '"ARCSEC": OP%(9) = 6
                Term# = ATN(RTerm# / SQR(RTerm# * RTerm# - 1)) + SGN(SGN(RTerm#) - 1) * 1.57079637050629#
               
                CASE 10                 '"ARCCSC": OP%(10) = 6
                Term# = ATN(RTerm# / SQR(RTerm# * RTerm# - 1)) + (SGN(RTerm#) - 1) * 1.57079637050629#
               
                CASE 11                 '"ARCCOT": OP%(11) = 6
                Term# = ATN(RTerm#) + 2 * ATN(1)
               
                CASE 12                 '"SINH": OP%(12) = 4
                Term# = (EXP(RTerm#) - EXP(-RTerm#)) / 2
               
                CASE 13                 '"TANH": OP%(13) = 4
                Term# = (EXP(RTerm#) - EXP(-RTerm#)) / (EXP(RTerm#) + EXP(-RTerm#))
               
                CASE 14                 '"SECH": OP%(14) = 4
                Term# = 2 / (EXP(RTerm#) + EXP(-RTerm#))
               
                CASE 15                 '"CSCH": OP%(15) = 4
                Term# = 2 / (EXP(RTerm#) - EXP(-RTerm#))
               
                CASE 16                 '"COTH": OP%(16) = 4
                Term# = (EXP(RTerm#) + EXP(-RTerm#)) / (EXP(RTerm#) - EXP(-RTerm#))
               
                CASE 17                 '"SEC": OP%(17) = 3
                Term# = 1 / COS(RTerm#)
               
                CASE 18                 '"CSC": OP%(18) = 3
                Term# = 1 / SIN(RTerm#)
               
                CASE 19                 '"COT": OP%(19) = 3
                Term# = 1 / TAN(RTerm#)
               
                CASE 20                 '"SIN": OP%(20) = 3
                Term# = SIN(RTerm#)
               
                CASE 21                 '"COS": OP%(21) = 3
                Term# = COS(RTerm#)
               
                CASE 22                 '"TAN": OP%(22) = 3
                Term# = TAN(RTerm#)
               
                CASE 23                 '"ATN": OP%(23) = 3
                Term# = ATN(RTerm#)
               
                CASE 24                 '"LOG": OP%(24) = 3
                IF RTerm# <= 0# GOTO ErrorExit
                Term# = LOG(RTerm#)
               
                CASE 25                 '"EXP": OP%(25) = 3
                Term# = EXP(RTerm#)
               
                CASE 26                 '"SQR": OP%(26) = 3
                IF RTerm# < 0# GOTO ErrorExit
                Term# = SQR(RTerm#)
               
                CASE 27                 '"CLG": OP%(27) = 3
                IF RTerm# <= 0# GOTO ErrorExit
                Term# = LOG(RTerm#) / LOG(10#)  '07/16/90

                CASE 28
                Term# = ABS(RTerm#)

                CASE 29
                Term# = NOT RTerm#

              END SELECT

              Incoming$ = LeftSide$ + LTRIM$(STR$(Term#)) + RightSide$
              LeftSide$ = "": Numeric$ = "": RightSide$ = ""
              RTerm# = 0: Term# = 0
           ELSE
              EXIT DO
           END IF
        LOOP
    NEXT




'***** Factorial .............................................................
    DO
       Position% = INSTR(Incoming$, "!")
       IF Position% THEN
          RightSide$ = MID$(Incoming$, Position% + 1)
          FOR L% = Position% - 1 TO MaxInt%(Position% - 5, 1) STEP -1
              IF INSTR("12434567890", MID$(Incoming$, L%, 1)) = 0 THEN EXIT FOR
              IF L% = Position% - 5 GOTO ErrorExit
          NEXT
          Numeric# = VAL(MID$(Incoming$, 1 + L%))
          LeftSide$ = LEFT$(Incoming$, L%)
          IF (Numeric# < 0#) OR (Numeric# > 170) GOTO ErrorExit
          Incoming$ = LeftSide$ + LTRIM$(STR$(Factorial#(CINT(Numeric#)))) + RightSide$
          LeftSide$ = "": Numeric# = 0: RightSide$ = ""
       ELSE
          EXIT DO
       END IF
    LOOP
   
    GOSUB DoubleSign    'removes occurrences of double signs
                        'for example, "--" is changed to "+"



'***** Exponentiation ........................................................
    DO
       Position% = INSTR(Incoming$, "^")
       IF Position% = 1 GOTO ErrorExit
       IF Position% > 1 THEN
          
          GOSUB TermBlock
        
          Term$ = LTRIM$(STR$(LTerm# ^ RTerm#))
          Incoming$ = LeftSide$ + Term$ + RightSide$
          IF Term$ = Incoming$ THEN
             LeftSide$ = ""
             RightSide$ = ""
             LTerm# = 0
             RTerm# = 0
             Term$ = ""
             GOTO Done
          END IF
       ELSE
          EXIT DO
       END IF
    LOOP



'***** Mutiplication & Division ..............................................
    DO
       QPLenIncoming% = QPLen%(Incoming$)
       PstnMult% = INSTR(Incoming$, "*")
       IF PstnMult% = 0 THEN PstnMult% = QPLenIncoming%
       PstnDiv% = INSTR(Incoming$, "/")
       IF PstnDiv% = 0 THEN PstnDiv% = QPLenIncoming%
       PstnIDiv% = INSTR(Incoming$, "\")
       IF PstnIDiv% = 0 THEN PstnIDiv% = QPLenIncoming%
       PstnMod% = INSTR(Incoming$, "MOD")
       IF PstnMod% = 0 THEN PstnMod% = QPLenIncoming%
      
       Position% = MinInt%(MinInt%(PstnMult%, PstnMod%), MinInt%(PstnDiv%, PstnIDiv%))
       IF Position% = QPLenIncoming% THEN Position% = 0
       IF Position% = 1 GOTO ErrorExit
       IF Position% > 1 THEN
         
          GOSUB TermBlock

          IF Position% = PstnMult% THEN
             Term# = LTerm# * RTerm#
          ELSEIF Position% = PstnDiv% THEN
             IF RTerm# = 0# GOTO ErrorExit
             Term# = LTerm# / RTerm#
          ELSEIF Position% = PstnIDiv% THEN
             IF RTerm# = 0# GOTO ErrorExit
             Term# = LTerm# \ RTerm#
          ELSEIF Position% = PstnMod% THEN
             Position = Position + 2
             GOSUB TermBlockR
             IF RTerm# = 0# GOTO ErrorExit
             Term# = LTerm# MOD RTerm#
          END IF

          Term$ = LTRIM$(STR$(Term#))
          Incoming$ = LeftSide$ + Term$ + RightSide$
          IF Term$ = Incoming$ THEN
             LeftSide$ = ""
             RightSide$ = ""
             LTerm# = 0
             RTerm# = 0
             Term$ = ""
             Term# = 0
             GOTO Done
          END IF
       ELSE
          EXIT DO
       END IF
    LOOP



'***** Addition & Subtraction ................................................
    DO
       PExp% = 2: MExp% = 1: QPLenIncoming% = QPLen%(Incoming$)

PFIND: PstnAdd% = INSTR(PExp%, Incoming$, "+")
       IF PstnAdd% THEN
          DE$ = MID$(Incoming$, PstnAdd% - 1, 1)
          IF (DE$ = "D") OR (DE$ = "E") THEN
             PExp% = PstnAdd% + 1
             GOTO PFIND
          END IF
       ELSE
          PstnAdd% = QPLenIncoming%
       END IF

MFIND: Ticker = Ticker + 1
       IF Ticker = QPLenIncoming% + 1 GOTO RelOP
       PstnSub% = INSTR(MExp%, Incoming$, "-")
       IF PstnSub% = 1 THEN
          IF QPLen%(STR$(VAL(Incoming$))) = QPLenIncoming% GOTO Done
          MExp% = 2
          GOTO MFIND
       END IF
       IF PstnSub% THEN
          DE$ = MID$(Incoming$, PstnSub% - 1, 1)
          IF DE$ < "0" OR DE$ > "9" THEN
          'IF (DE$ = "D") OR (DE$ = "E") THEN
             MExp% = PstnSub% + 1
             GOTO MFIND
          END IF
       ELSE
          PstnSub% = QPLenIncoming%
       END IF
       Position% = MinInt%(PstnAdd%, PstnSub%)
       IF Position% = QPLenIncoming% THEN Position% = 0
       IF Position% THEN

          GOSUB TermBlock
       
          IF Position% = PstnAdd% THEN
             Term# = LTerm# + RTerm#
          ELSEIF Position% = PstnSub% THEN
             Term# = LTerm# - RTerm#
          END IF
          Ticker = 0
          Term$ = LTRIM$(STR$(Term#))
          Incoming$ = LeftSide$ + Term$ + RightSide$
          IF Term$ = Incoming$ OR Incoming$ = "-1=-1" THEN
             LeftSide$ = ""
             RightSide$ = ""
             LTerm# = 0
             RTerm# = 0
             Term$ = ""
             Term# = 0
             DE$ = ""
             GOTO Done
          END IF
       ELSE
          EXIT DO
       END IF
    LOOP


RelOP:
'***** Relational Operators ..............................................
    DO
       QPLenIncoming% = QPLen%(Incoming$)
       Pstn1% = INSTR(Incoming$, "=")
       IF Pstn1% = 0 THEN Pstn1% = QPLenIncoming%
       Pstn2% = INSTR(Incoming$, ">")
       IF Pstn2% = 0 THEN Pstn2% = QPLenIncoming%
       Pstn3% = INSTR(Incoming$, "<")
       IF Pstn3% = 0 THEN Pstn3% = QPLenIncoming%
       Position% = MinInt%(Pstn1%, MinInt%(Pstn2%, Pstn3%))

       IF Position% = QPLenIncoming% THEN EXIT DO
       IF Position% = 1 GOTO ErrorExit
       IF Position% > 1 THEN
        
          IF MID$(Incoming$, Position% - 1, 1) = CHR$(34) THEN
             Begin% = QInstrB%(Position% - 2, Incoming$, CHR$(34))
             LTerm$ = MID$(Incoming$, Begin% + 1, Position% - Begin% - 2)
             LeftSide$ = LEFT$(Incoming$, Begin% - 1)
             LastDig% = INSTR(Position% + 2, Incoming$, CHR$(34))
             RTerm$ = MID$(Incoming$, Position% + 2, LastDig% - Position% - 2)
             RightSide$ = MID$(Incoming$, LastDig% + 1)

             IF Position% = Pstn1% THEN
                Term# = LTerm$ = RTerm$
             ELSEIF Position% = Pstn2% THEN
                Term# = LTerm$ > RTerm$
             ELSEIF Position% = Pstn3% THEN
                Term# = LTerm$ < RTerm$
             END IF

          ELSE
             GOSUB TermBlock

             IF Position% = Pstn1% THEN
                Term# = LTerm# = RTerm#
             ELSEIF Position% = Pstn2% THEN
                Term# = LTerm# > RTerm#
             ELSEIF Position% = Pstn3% THEN
                Term# = LTerm# < RTerm#
             END IF

          END IF

          Term$ = LTRIM$(STR$(Term#))
          Incoming$ = LeftSide$ + Term$ + RightSide$

          IF Term$ = Incoming$ THEN
             LeftSide$ = ""
             RightSide$ = ""
             LTerm# = 0
             RTerm# = 0
             Term$ = ""
             Term# = 0
             GOTO Done
          END IF
       ELSE
          EXIT DO
       END IF
    LOOP



'***** Logical Operators ..............................................

    FOR Functn% = 1 TO UBOUND(Logic$)
        DO
           Position% = INSTR(Incoming$, Logic$(Functn%))
           IF Position% THEN
              SELECT CASE Functn%
                 CASE 1                         'AND
                    GOSUB TermBlock
                    Position% = Position% + LEN(Logic$(Functn%)) - 1
                    GOSUB TermBlockR
                    Term# = LTerm# AND RTerm#
                 CASE 2                         'OR
                    GOSUB TermBlock
                    Position% = Position% + LEN(Logic$(Functn%)) - 1
                    GOSUB TermBlockR
                    Term# = LTerm# OR RTerm#
                 CASE ELSE
              END SELECT

              Incoming$ = LeftSide$ + LTRIM$(STR$(Term#)) + RightSide$
              LeftSide$ = "": Numeric$ = "": RightSide$ = ""
           ELSE
              EXIT DO
           END IF
        LOOP
    NEXT






'***** Exit the Function .....................................................
Done:      Evaluate# = VAL(Incoming$)
           EXIT FUNCTION

ErrorExit: Evaluate# = 0
           Equation$ = "%" + Equation$
           EXIT FUNCTION


'***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *****

'----- Gosubs ...............................................................

'----- Isolate the left$ & left#, right# & right$ around the operator
TermBlock:
           Valid$ = "1234567890.-+DE"
           Begin% = Position%
           DO
              Valid% = 1
              Begin% = Begin% - 1
              P% = INSTR(Valid$, MID$(Incoming$, Begin%, 1))
              IF P% THEN
                 IF ((P% = 12) OR (P% = 13)) AND (Sign% = 0) AND (Begin% > 1) THEN
                    IF INSTR("1234567890.", MID$(Incoming$, Begin% - 1, 1)) THEN
                       Valid% = 0: Begin% = Begin% + 1
                    END IF
                    Sign% = -1
                 ELSEIF (P% = 14) OR (P% = 15) THEN
                    Sign% = 0: Valid$ = "1234567890.-+"
                 ELSEIF P% > 11 THEN
                    Valid% = 0
                    IF Sign THEN Begin = Begin + 1       '6/20/90
                 END IF
              ELSE
                 Valid% = 0: Begin% = Begin% + 1
              END IF
           LOOP WHILE (Valid% = 1) AND (Begin% > 1)
           LeftSide$ = LEFT$(Incoming$, Begin% - 1)
           LTerm# = VAL(MID$(Incoming$, Begin%, Position% - Begin%))

TermBlockR:
           RightSide$ = MID$(Incoming$, Position% + 1)
           RTerm# = VAL(RightSide$)
           IF RightSide$ = LTRIM$(STR$(RTerm#)) THEN
              RightSide$ = ""
              GOTO FinisTB
           END IF
           LastDig% = 1: LastDigOld% = 0: EX% = 0: DP% = 0
           QPlenRightSide% = QPLen%(RightSide$)
           DO WHILE LastDig% <= QPlenRightSide%
              Digit$ = MID$(RightSide$, LastDig%, 1)
              IF LastDig% = 1 THEN
                 IF INSTR("+-", Digit$) THEN
                    IF (SGN(RTerm#) = 1) AND (Digit$ = "+") THEN
                       LastDig% = LastDig% + 1
                    ELSEIF (SGN(RTerm#) = -1) AND (Digit$ = "-") THEN
                       LastDig% = LastDig% + 1
                    ELSE
                       EXIT DO
                    END IF
                 END IF
              END IF
              IF INSTR("1234567890", Digit$) THEN
                 LastDig% = LastDig% + 1
              ELSEIF Digit$ = "." THEN
                 IF DP% = 0 THEN LastDig% = LastDig% + 1
                 DP% = 1
              ELSEIF INSTR("DE", Digit$) THEN
                 IF EX% = 0 THEN LastDig% = LastDig% + 1
                 EX% = 1
              ELSEIF (INSTR("+-", Digit$) <> 0) AND (INSTR("DE", MID$(RightSide$, MaxInt%(1, LastDig% - 1), 1)) <> 0) THEN
                 LastDig% = LastDig% + 1
              END IF
              IF LastDig% = LastDigOld% THEN EXIT DO
              LastDigOld% = LastDig%
           LOOP
           RightSide$ = MID$(RightSide$, LastDig%)

FinisTB:   P% = 0
           Begin% = P%
           Sign% = P%
           LastDig% = P%
           LastDigOld% = P%
           QPlenRightSide% = P%
           EX% = P%
           DP% = P%
           Valid$ = ""
           Digit$ = ""
EndTB:     RETURN


'----- Remove double occurrences of plus and minus by cancellation
RemoveOne:  Remove% = -1
DoubleSign: PP% = INSTR(Incoming$, "++")
            IF PP% THEN
               MID$(Incoming$, PP%, 2) = "+ "
               GOTO RemoveOne
            END IF
            MP% = INSTR(Incoming$, "-+")
            IF MP% THEN
               MID$(Incoming$, MP%, 2) = "- "
               GOTO RemoveOne
            END IF
            MM% = INSTR(Incoming$, "--")
            IF MM% THEN
               MID$(Incoming$, MM%, 2) = "+ "
               GOTO RemoveOne
            END IF
            IF Remove% THEN
               Remove% = 0
               Incoming$ = Compact$(Incoming$)
            END IF
EndDS:      RETURN

END FUNCTION

