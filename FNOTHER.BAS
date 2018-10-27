'********** FNOther.Bas

'Copyright (c) 1988 Crescent Software

'Functions written by Don Malin, Paul Passarelli, and Ethan Winer


DEFINT A-Z
DECLARE FUNCTION Bin2Num% (Binary$)
DECLARE FUNCTION C2F! (CTemp!)
DECLARE FUNCTION Delimit% (Work$, Delim$)
DECLARE FUNCTION Eval# (E$)
DECLARE FUNCTION ExpandTab$ (X$, NumSpaces)
DECLARE FUNCTION F2C! (FTemp!)
DECLARE FUNCTION InCount% (Source$, Search$)
DECLARE FUNCTION LastFirst$ (X$)
DECLARE FUNCTION LastLast$ (X$)
DECLARE FUNCTION Num2Bin$ (Number)
DECLARE FUNCTION Num2Bin2$ (Number)
DECLARE FUNCTION Pad$ (X!, Places)
DECLARE SUB Parse (Work$, Delim$, Array$())
DECLARE FUNCTION ParseStr$ (X$)
DECLARE SUB QPrint0 (X$, Colr)                  'assembler - used in Tab demo
DECLARE FUNCTION Rand! (Lo!, Hi!)
DECLARE FUNCTION ShrinkTab$ (X$, NumSpaces)
DECLARE FUNCTION Signed% (X&)
DECLARE FUNCTION UnParseStr$ (X$)
DECLARE FUNCTION UnSigned& (X%)


'----- expanding and contracting Tabs

CLS
QPrint0 "                   12345678901234567890123456789012345678901234", -1
PRINT

Test$ = CHR$(9) + CHR$(9) + "Test" + SPACE$(8) + "One, two, three."
QPrint0 "Before expanding: " + CHR$(34) + Test$ + CHR$(34), 7
PRINT

NumSpaces = 8                   'set tab stops every eight spaces
Test$ = ExpandTab$(Test$, NumSpaces)
QPrint0 " After expanding: " + CHR$(34) + Test$ + CHR$(34), 7
PRINT

Test$ = ShrinkTab$(Test$, NumSpaces)
QPrint0 " After shrinking: " + CHR$(34) + Test$ + CHR$(34), 7
PRINT

Test$ = ExpandTab$(Test$, NumSpaces)
QPrint0 " After expanding: " + CHR$(34) + Test$ + CHR$(34), 7

GOSUB PMsg



'----- temperature conversion

INPUT "Enter a Fahrenheit temperature: ", Temp!
PRINT
PRINT STR$(Temp!); "ø converted to Centigrade equals "; STR$(F2C!(Temp!)); "ø"
PRINT
PRINT STR$(F2C!(Temp!)); "ø converted back again equals "; STR$(C2F!(F2C!(Temp!))); "ø"
GOSUB PMsg



'----- binary conversion

INPUT "Enter a number between -32768 and 32767: ", Value
PRINT
PRINT "Num2Bin$ returns it as: "; Num2Bin$(Value)
PRINT " and Num2Bin2$ returns: "; Num2Bin2$(Value)
PRINT "Bin2Num converts it to: "; LTRIM$(STR$(Bin2Num%(Num2Bin$(Value))))
GOSUB PMsg



'----- Parse PATH into separate components

'Comments below also show how to parse COMMAND$ for one or more switches.
'Delimit% returns the value to which the array must be dimensioned, and
'Parse unpacks the string into the array

Work$ = ENVIRON$("PATH")        'use this to parse the current PATH
'Work$ = COMMAND$               'use this for COMMAND$

Delim$ = "+,;_ "                'table of some common delimiters

J = Delimit%(Work$, Delim$) + 1 'see how many matching delimiters there are
REDIM Array$(J)                 '+1 is needed to account for the last item

Parse Work$, Delim$, Array$()   'Parse fills the array

PRINT "Your current path is:"
PRINT
PRINT TAB(5); Work$
PRINT
PRINT
PRINT "Broken out into each directory:"
PRINT
FOR X = 1 TO J
    PRINT TAB(5); "==> "; Array$(X)
NEXT
END

PMsg:

    LOCATE 25, 1
    PRINT "Press a key ";
    CALL WaitKey
    CLS
    RETURN

FUNCTION C2F! (DegC!) STATIC
   C2F! = DegC! * 1.8 + 32
END FUNCTION

FUNCTION Delimit% (Work$, Delim$) STATIC

   Counter% = 0

   FOR X% = 1 TO LEN(Delim$)
       Counter% = Counter% + InCount%(Work$, MID$(Delim$, X%, 1))
   NEXT X%

   Delimit% = Counter%

END FUNCTION

FUNCTION Eval# (E$) STATIC

    X$ = ""
    MinusOk% = 1                'a minus sign is okay only once, and only
                                '  if it precedes the first numeric character
    DecOk% = 1                  'only the first decimal point is okay

    FOR X% = 1 TO LEN(E$)

        Y$ = MID$(E$, X%, 1)

        IF Y$ = "-" AND MinusOk% THEN
           X$ = X$ + Y$
           MinusOk% = 0
        ELSEIF Y$ = "." AND DecOk% THEN
           X$ = X$ + Y$
           DecOk% = 0
        ELSEIF Y$ >= "0" AND Y$ <= "9" THEN
           X$ = X$ + Y$
           MinusOk% = 0
        END IF

    NEXT

    Eval# = VAL(X$)

END FUNCTION

FUNCTION ExpandTab$ (X$, NumSpaces%) STATIC

    Tabs% = InCount(X$, CHR$(9))                'Find Number of tab Chars.
    IF Tabs% THEN                               'Are there any?
                                                'make room for new string
       Work$ = SPACE$(LEN(X$) + 1 + (NumSpaces% - 1) * Tabs%)

       LSET Work$ = X$ + CHR$(0)                'Put existing string in it
                                                '  and a char. 0 for later
       Where% = 1                               'Set search position to 1

       FOR X% = 1 TO Tabs%                      'Do each tab
                                                'find the next Tab character
           Where% = INSTR(Where%, Work$, CHR$(9)) + 1

           Length% = Where% - 2                 'Calc length of left part
                                                'Calc spaces to next tab stop
           Sp% = Length% + NumSpaces% - (Length% MOD NumSpaces%) - Length%
                                                'Insert the spaces
           IF Where% > 1 THEN MID$(Work$, Where% - 1) = SPACE$(Sp%) + MID$(Work$, Where%)
       NEXT                                     'Assign the function looking
                                                '  for the char. 0
       ExpandTab$ = LEFT$(Work$, INSTR(Work$, CHR$(0)) - 1)
    ELSE                                        'No tabs.  Just assign the
       ExpandTab$ = X$                          '  function
    END IF

END FUNCTION

FUNCTION F2C! (DegF!) STATIC
   F2C! = (DegF! - 32) / 1.8
END FUNCTION

FUNCTION LastFirst$ (X$) STATIC

    Temp$ = LTRIM$(RTRIM$(X$))          'first strip leading/trailing spaces

    FOR X% = LEN(Temp$) TO 1 STEP -1     'seek separating blank
        IF MID$(Temp$, X%, 1) = " " THEN
           LastFirst$ = MID$(Temp$, X% + 1) + ", " + LEFT$(Temp$, X% - 1)
           EXIT FUNCTION
        END IF
    NEXT

END FUNCTION

FUNCTION LastLast$ (X$) STATIC

    T$ = LTRIM$(RTRIM$(X$))                     'strip leading/trailing spaces

    X% = INSTR(T$, ",")                           'seek separating comma
    IF X% = LEN(T$) OR X% <= 1 THEN EXIT FUNCTION 'exit now, avoid crash later

    LastLast$ = LTRIM$(RTRIM$(MID$(T$, X% + 1) + " " + LEFT$(T$, X% - 1)))

END FUNCTION

FUNCTION Pad$ (X!, Places%) STATIC

    X$ = STR$(X!)                       'make a string version of the number

    IF LEN(LTRIM$(X$)) > Places% THEN   'if after trimming a possible leading
       Pad$ = "%" + X$                  '  blank it's too long, add a "%"
       EXIT FUNCTION                    '  to show an error and go away
    END IF

    X$ = MID$(X$, 2)                    'discard the leading blank or "-" sign
    Pad$ = MID$("-", SGN(X!) + 2) + STRING$(Places% - LEN(X$) + (SGN(X!) = -1), "0") + X$
    '            ^add minus if needed       ^create the zeros    ^less one if negative

END FUNCTION

SUB Parse (Work$, Delim$, Array$())

    BeginPtr% = 1
    Element% = 1

    FOR EndPtr% = 1 TO LEN(Work$)
        IF INSTR(Delim$, MID$(Work$, EndPtr%, 1)) THEN
           Array$(Element%) = MID$(Work$, BeginPtr%, EndPtr% - BeginPtr%)
           Element% = Element% + 1
           BeginPtr% = EndPtr% + 1
        END IF
    NEXT

    Array$(Element%) = MID$(Work$, BeginPtr%)

END SUB

'This function accepts a string of the form "12, 34, 56" and returns it
'packed as CHR$(12) + CHR$(34) + CHR$(56) -- it is intended for parsing
'printer codes entered by a user.
'
FUNCTION ParseStr$ (X$) STATIC

    Comma% = 0

    DO
       Code$ = Code$ + CHR$(VAL(MID$(X$, Comma% + 1)))
       Comma% = INSTR(Comma% + 1, X$, ",")
    LOOP WHILE Comma%

    ParseStr$ = Code$
    Code$ = ""

END FUNCTION

FUNCTION Rand! (Lo!, Hi!) STATIC

   RANDOMIZE TIMER
   Rand! = RND(1) * (Hi! - Lo!) + Lo!

END FUNCTION

FUNCTION ShrinkTab$ (X$, NumSpaces%) STATIC

    Work$ = X$
    Ps% = 1
    PsNew% = 1
    DO
        Ps% = INSTR(Ps%, Work$, SPACE$(NumSpaces%))
        IF Ps% = 0 THEN EXIT DO

        PsNew% = INSTR(PsNew%, Work$, SPACE$(NumSpaces%))
       
        TabStop% = (((Ps% - 1) \ NumSpaces%) * NumSpaces%) + 8

        Work$ = LEFT$(Work$, PsNew% - 1) + CHR$(9) + MID$(Work$, TabStop% + 1)
       
        Ps% = TabStop% + 1
        PsNew% = PsNew% + 1
    LOOP

    ShrinkTab$ = Work$                          'assign the expanded string

END FUNCTION

FUNCTION Signed% (X&) STATIC
    IF X& > 32767 THEN
       Signed% = X& - 65536
    ELSE
       Signed% = X&
    END IF
END FUNCTION

'This function accepts a string of the form CHR$(12) + CHR$(34) + CHR$(56)
'and unpacks it to "12,34,56" - it is intended as a complement to ParseStr$
'and allows printer codes already packed to be unpacked and edited.  The
'comment below shows how to add a space if you'd like to get "12, 34, 56".
'
FUNCTION UnParseStr$ (X$) STATIC

    FOR X% = 1 TO LEN(X$)
        Temp$ = Temp$ + MID$(STR$(ASC(MID$(X$, X%, 1))), 2)
        IF X% < LEN(X$) THEN Temp$ = Temp$ + ","
        '                                use ", " to add a space after commas
    NEXT

    UnParseStr$ = Temp$
    Temp$ = ""
   
END FUNCTION

FUNCTION UnSigned& (X%) STATIC
    IF X% < 0 THEN
       UnSigned& = X% + 65536
    ELSE
       UnSigned& = X%
    END IF
END FUNCTION

