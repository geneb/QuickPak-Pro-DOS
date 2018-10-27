' SciFormat.BAS
' Copyright (c) 1992 Shaun Blain
'
'
'   Demo program of the SciFormat and round functions. The combination of
'   the two function take a numeric string and format it in expontential
'   format.
'
'   Calling format:
'
'   Form$ = SciFormat$(Amount$, bpt, apt)
'        Amount$ = the numeric string to be formatted
'        bpt = number of places before the decimal point
'        apt = number of places after the decimal point
'
'   Comp$ = Round$(Amount$, ExpKick)
'        Amount$ = numeric string to be rounded
'        ExpKick = flag to increment the exponent, due to shifting
'                  the decimal place left one place.
'

DEFINT A-Z
DECLARE FUNCTION SciFormat$ (Amount$, bpt, apt)
DECLARE FUNCTION Round$ (Amount$, ExpKick)
   

DO
  INPUT "Enter a value: ", X$
  IF LEN(X$) = 0 THEN EXIT DO

  PRINT "Unformatted value = "; X$
  PRINT "Formatted value = "; SciFormat$(X$, 1, 2)
  PRINT "Formatted value = "; SciFormat$(X$, 2, 3)
  PRINT

LOOP

FUNCTION Round$ (Passed$, ExpKick) STATIC
'
' Copyright (c) 1992 Shaun Blain
'
'
' Function to round off a numeric string, and also set it to the
' correct length.
'
' Uses the last number in the string to determine if a number is rounded
' up or left alone. If a number is rounded, the CF (carry flag) is set
' until there is no more to carry. The ExpKick (exponent kickup) is set when
' a number is padded on the front end due to the carrying process. The
' ExpKick variable alerts the calling routine that it should increment the
' exponent value by one.
'
' This routine could be considered superfluous, but it makes the whole
' thing easier to understand. <IMHO>
'
   
    Zero$ = "0"
    CF = 0                                      'carry flag
    ExpKick = 0                                 'kick up the exponent

    '--- do not mess with the original string
    Amount$ = LTRIM$(RTRIM$(Passed$))
    DPt = INSTR(Amount$, ".")
    TLen = LEN(Amount$) - 1

    '--- check to see if we should round up
    ND = TLen                                   'find the next digit
    LD = VAL(RIGHT$(Amount$, 1))                'obtain the load digit
    IF LD >= 5 THEN CF = -1                     'set cf to carry?

    '--- keep looping while the carry flag is set
    DO WHILE CF
        '--- yes, we need to round up

        'check if we need to pad the front end of the string
        IF ND = 0 THEN                          'set the next digit
            ND = 1
            Amount$ = " " + Amount$             'pad the string
            ExpKick = 1                         'set the exp. alert flag
        END IF

        IF LD > 9 THEN                          'load digit > 9?
            CF = -1                             'yes, we will need to carry
            MID$(Amount$, ND, 1) = Zero$        'set current digit to zero
        ELSE
            'load digit < 10 coming in

            'obtain int. value and inc by 1
            TVal = VAL(MID$(Amount$, ND, 1)) + 1

            'if the inc value is less then 10, insert it into the string
            IF TVal < 10 THEN
                MID$(Amount$, ND, 1) = RTRIM$(LTRIM$(STR$(TVal)))
                CF = 0                          'no need to carry
            ELSE
                CF = -1                         'one more time through
                MID$(Amount$, ND, 1) = Zero$    'set current digit to zero
            END IF
        END IF

       
        ND = ND - 1                             'dec next digit
        IF ND = DPt THEN ND = ND - 1            'we don't want the decimal point
        IF ND > 0 THEN
            'get next digit from the string
            LD = VAL(MID$(Amount$, ND, 1)) + 1
        ELSE
            LD = 1                               'were past the beg., assign a value
        END IF

        
    LOOP
           
    '--- did we have to pad the front of the string?
    IF ExpKick THEN
        'YES!, so shift the deciaml point to the left
        T$ = LEFT$(Amount$, DPt) + MID$(Amount$, DPt + 2, TLen - DPt)
        T$ = LEFT$(T$, TLen)
        Amount$ = LEFT$(T$, DPt - 1) + "." + RIGHT$(T$, LEN(T$) - DPt + 1)
    END IF

    '--- assign the function value, and insure the proper length
    Round$ = LEFT$(LTRIM$(Amount$), TLen)

END FUNCTION

FUNCTION SciFormat$ (Amount$, bpt, apt) STATIC
'
' Copyright (c) 1992 Shaun Blain
'
' Function to format a numeric string into a scientific format string.
' IE. 0.000006 -> 6.0D-06
'
' Amount$ .... the numeric string to convert
' bpt     .... number of places before the decimal point in the output string
' apt     .... number of places after the decimal point in the output string
'
'
    IF NOT BeenHere THEN            'do this only once
      BeenHere = -1
      Zero$ = "0"                   ' save a little memory
      Plus$ = "+"                   ' plus sign
      Minus$ = "-"                  ' negative sign
      Pt$ = "."                     ' decimal point
      DPt = 0                       ' where the decimal point is
    END IF

    TLen = bpt + apt + 2            ' total required length (apt+bpt+dpt+sign)
    
    'make a copy of the string and clean it up
    TAmount$ = LTRIM$(RTRIM$(Amount$))

    'make sure it is not a null string, if it is, FIX IT!
    IF LEN(TAmount$) = 0 THEN
        Last$ = "0.00"              'if it is null, we will return 0
        GOTO QExit                  'this will fix it.
    END IF
    
    'obtain the sign of the number
    IF LEFT$(TAmount$, 1) = Plus$ OR LEFT$(TAmount$, 1) = Minus$ THEN
        Sign$ = LEFT$(TAmount$, 1)                      'save the sign
        TAmount$ = RIGHT$(TAmount$, LEN(TAmount$) - 1)  'remove sign from the
    ELSE                                                ' string
        Sign$ = ""                                      'no sign
    END IF


    'trim any leading zero's
    DO WHILE LEFT$(TAmount$, 1) = Zero$
        TAmount$ = RIGHT$(TAmount$, LEN(TAmount$) - 1)
    LOOP

    'find the decimal point
    DPt = INSTR(TAmount$, Pt$)
    IF DPt = 0 THEN                         'this is science, we have to have
        DPt = LEN(TAmount$) + 1             ' a decimal point
        TAmount$ = TAmount$ + Pt$           'even if it does float!
    END IF

    'check that we have a long enough string
    'It is easier to do this way, rather than a lot of calculations below
    IF LEN(TAmount$) < TLen THEN
        DO
            TAmount$ = TAmount$ + Zero$     'if we don't, pad the end of the
        LOOP UNTIL LEN(TAmount$) = TLen     ' string with zeros
    END IF

    '--- now act according to where the decimal point is
    SELECT CASE DPt

        CASE IS > 1
            'extract the numbers to the left & right of the decimal point
            Cnt = 1
            DO
                T = ASC(MID$(TAmount$, Cnt, 1)) - 48    'get its value
                IF T >= 0 AND T <= 9 THEN               'is it a digit?
                    Work$ = Work$ + LTRIM$(STR$(T))     'Yes, so add  it
                END IF
                Cnt = Cnt + 1                           'inc char pointer
            LOOP UNTIL LEN(Work$) = bpt         'loop until we have
                                                'everything we want in front
                                                ' of the decimal point
            
            Work$ = Work$ + Pt$                 'add the deciaml point

            DO
                T = ASC(MID$(TAmount$, Cnt, 1)) - 48    'get the char's value
                IF T >= 0 THEN Work$ = Work$ + LTRIM$(STR$(T))
                Cnt = Cnt + 1
            LOOP UNTIL LEN(Work$) = TLen

           
        'between 0.0 and 1.0, absolute
        CASE ELSE
            ' everything to the right of the decimal point
            MID$(TAmount$, 1) = Zero$

            'trim any leading zeros, hey just like above
            DPt = 0
            DO WHILE LEFT$(TAmount$, 1) = Zero$
                TAmount$ = RIGHT$(TAmount$, LEN(TAmount$) - 1)
                DPt = DPt - 1
            LOOP

            'make sure it is long enough
            IF LEN(TAmount$) < TLen THEN
                DO
                    TAmount$ = TAmount$ + Zero$     'pad with zeros as req'd
                LOOP UNTIL LEN(TAmount$) >= TLen
            END IF

            
            'now build the string
            Cnt = 1
            DO
                T = ASC(MID$(TAmount$, Cnt, 1)) - 48    'get its value
                IF T >= 0 AND T <= 9 THEN               'is it a digit?
                    Work$ = Work$ + LTRIM$(STR$(T))     'Yes, so add  it
                END IF
                Cnt = Cnt + 1                           'inc char pointer
            LOOP UNTIL LEN(Work$) = bpt         'loop until we have
                                                'everything we want in
                                                'front of the decimal point
            
            Work$ = Work$ + Pt$                 'add the decimal point

            DO
                T = ASC(MID$(TAmount$, Cnt, 1)) - 48    'get the char's value
                IF T >= 0 THEN Work$ = Work$ + LTRIM$(STR$(T))  'add if a number
                Cnt = Cnt + 1                                   'inc pointer
            LOOP UNTIL LEN(Work$) = TLen        'loop until we have everything


    END SELECT

    '---- now round off the number
    Last$ = Round$(Work$, ExpKick)
    IF ExpKick THEN DPt = DPt + 1               'bump the exp up one since we
                                                ' had to slide the decimal
                                                ' point to the left

QExit:                                          'used for null strings
    '---- now format the exponent string
    IF Last$ = "0.00" OR DPt = 0 THEN
        Exp$ = "D+00"
    ELSE
        IF DPt > 0 THEN                         'positive exponent
            IF DPt - bpt - 1 >= 0 THEN
                Exp$ = "D+" + LTRIM$(STR$(DPt - bpt - 1))
            ELSE
                Exp$ = "D" + LTRIM$(STR$(DPt - bpt - 1))
            END IF
        ELSE
            Exp$ = "D" + LTRIM$(STR$(DPt))       'negative exponent
        END IF
       
        'pad the exponent string with another zero if necessary
        IF LEN(Exp$) < 4 THEN Exp$ = LEFT$(Exp$, 2) + Zero$ + RIGHT$(Exp$, 1)
    END IF
    
    '---- assign the function return value
    SciFormat$ = Sign$ + Last$ + Exp$
    Work$ = ""
    Last$ = ""
    Exp$ = ""

END FUNCTION
