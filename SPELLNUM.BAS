'********** SpellNum.Bas - Creates a spelled out version of a number

'Copyright (c) 1989 Don Malin
'Copyright (c) 1989 Crescent Software


DEFINT A-Z

'----- Look up tables for number words
CONST NumTbl$ = "123456789"
CONST NumNames$ = "One  Two  ThreeFour Five Six  SevenEightNine Ten"
CONST Teens$ = "Eleven    Twelve    Thirteen  Fourteen  Fifteen   Sixteen   Seventeen Eighteen  Nineteen"
CONST Tens$ = "Ten     Twenty  Thirty  Forty   Fifty   Sixty   Seventy Eighty  Ninety"
CONST Powers3$ = "Thousand Million  Billion  Trillion"

DECLARE FUNCTION FUsing$ (Number$, Mask$)
DECLARE FUNCTION SpellNumber$ (Number$)


'--- Remove the following example code before adding this to your own program.

CLS                                             'Clear the screen
Mask$ = "###############.##"                    'Make a mask for "FUsing$"

INPUT "Enter amount for check: ", Amount#       'Get a number from user
Num$ = FUsing$(STR$(Amount#), Mask$)            'Format the number into a $
PRINT SpellNumber$(Num$);                       'Print the whole number part

PRINT " Dollar";                                'Let's do dollars and cents
IF INT(VAL(Num$)) <> 1 THEN PRINT "s";          'Anything but "One" is plural
PRINT " and "; MID$(Num$, INSTR(Num$, ".") + 1); " Cents"  'Do cents part

'******* Returns a spelled out version of a number
FUNCTION SpellNumber$ (StrNum$) STATIC

    SpellNumber$ = ""                           'Clear the function
    Num$ = LTRIM$(RTRIM$(StrNum$))              'Trim off any spaces

    X = INSTR(Num$, ".")                        'Trim off any decimal places
    IF X THEN Num$ = LEFT$(Num$, X - 1)
    
    Length = LEN(Num$)                          'Get the length
    IF Length > 15 THEN EXIT FUNCTION           'Exit if bigger than trillions

    FOR N = Length TO 1 STEP -1                 'Step backwards through number

        X = INSTR(NumTbl$, MID$(Num$, N, 1)) - 1 'Look up the digit in table

        SELECT CASE (Length - N) MOD 3          'Branch according to digit
                                                '  position
           '----- Ones digit
           CASE 0
              IF N < Length THEN                'If not on last digit, look
                 FOR Temp = N TO N - 2 STEP -1  '  for non 0 digit
                    IF Temp > 0 THEN            'If not past end of number
                       Word$ = MID$(Num$, Temp, 1)
                                                'If this is a non 0 digit,
                                                '  put power word in sentence
                       IF Word$ <> "0" AND Word$ <> "-" THEN
                          Temp = ((Length - N) \ 3 - 1) * 9 + 1
                          Word$ = RTRIM$(MID$(Powers3$, Temp, 9))
                          Sentence$ = Word$ + " " + Sentence$
                          EXIT FOR              'Bail out of search loop
                       END IF
                    END IF
                 NEXT
              END IF

              IF X > -1 THEN                    'If digit found, get the word
                 Word$ = MID$(NumNames$, X * 5 + 1, 5)
                 
                 IF N > 1 THEN                  'If left digit is one, use
                                                '  "Teen" table
                    IF MID$(Num$, N - 1, 1) = "1" THEN
                       Word$ = MID$(Teens$, X * 10 + 1, 10)
                       N = N - 1                'Skip the Tens digit
                    END IF
                 END IF
              END IF

           '----- Tens digit
           CASE 1
              IF X > -1 THEN                    'Find word in "Tens" table
                 Word$ = MID$(Tens$, X * 8 + 1, 8)
              END IF

           '----- Hundreds digit
           CASE 2
              IF X > -1 THEN                    'Find word in number table
                 Word$ = MID$(NumNames$, X * 5 + 1, 5)
                                                'Add the word "Hundred"
                 Word$ = RTRIM$(Word$) + " Hundred"
              END IF

        END SELECT

        IF N = 1 AND X = -1 THEN                'Look for a minus sign at
           IF MID$(Num$, N, 1) = "-" THEN       '  digit one
              Word$ = "Negative"                'Add it to sentence
              X = 0
           END IF
        END IF
                                                'If digit is non zero, add
                                                '  the word to the sentence
        IF X > -1 THEN Sentence$ = RTRIM$(Word$) + " " + Sentence$
    NEXT

    SpellNumber$ = RTRIM$(Sentence$)            'Assign the function

    Num$ = ""                                   'Clean up work strings
    Word$ = ""
    Sentence$ = ""

END FUNCTION

