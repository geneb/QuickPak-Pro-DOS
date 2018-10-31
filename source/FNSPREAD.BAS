'********* FNSPREAD.BAS

'Copyright (c) 1988 Crescent Software
'Lotus "@" functions by Bill Eppler, Ed Ernst, and Ethan Winer


'This file contains a complete set of scientific, financial, and other
'general purpose functions.  Because many of them are "one-liners" or
'at least fairly short, they have all been gathered into a single file.


DEFINT A-Z


'----- Assembler function helpers

DECLARE FUNCTION ASCII% (X$)                    'asm - used by ROUND#
DECLARE FUNCTION FUsing$ (Number$, Mask$)       'asm - used by ROUND#
DECLARE FUNCTION MaxD# (SEG Element#, NumEls)   'asm - used by MAX#
DECLARE FUNCTION MinD# (SEG Element#, NumEls)   'asm - used by MIN#



'----- BASIC Financial and scientific functions

DECLARE FUNCTION QPACOS# (X#)
DECLARE FUNCTION QPASIN# (X#)
DECLARE FUNCTION QPATAN2# (X#, Y#)
DECLARE FUNCTION QPAVG# (Array#())
DECLARE FUNCTION QPCINT# (Pv#, Intr#, Term)
DECLARE FUNCTION QPCOUNT% (Array#())
DECLARE FUNCTION QPCTERM# (Pv#, Fv#, Intr#)
DECLARE FUNCTION QPDDB# (Cost#, Sal#, Life, Per, M!)
DECLARE FUNCTION QPFV# (Pmt#, Intr#, Term)
DECLARE FUNCTION QPFVD# (Pmt#, Intr#, Term)
DECLARE FUNCTION QPFVN# (Fv#, Pmt#, Intr#)
DECLARE FUNCTION QPFVND# (Fv#, Pmt#, Intr#)
DECLARE FUNCTION QPFVP# (Fv#, Intr#, Term)
DECLARE FUNCTION QPFVPD# (Fv#, Intr#, Term)
DECLARE FUNCTION QPIRR# (Intr#, Array#())
DECLARE FUNCTION QPLOG10# (X#)
DECLARE FUNCTION QPMAX# (Array#())
DECLARE FUNCTION QPMIN# (Array#())
DECLARE FUNCTION QPNPV# (Intr#, Array#())
DECLARE FUNCTION QPPMT# (Pv#, Intr#, Term, Bal#)
DECLARE FUNCTION QPPMTD# (Pv#, Intr#, Term, Bal#)
DECLARE FUNCTION QPPV# (Pmt#, Intr#, Term, Bal#)
DECLARE FUNCTION QPPVD# (Pmt#, Intr#, Term, Bal#)
DECLARE FUNCTION QPPVN# (Pmt#, Intr#, Pv#, Bal#)
DECLARE FUNCTION QPPVND# (Pmt#, Intr#, Pv#, Bal#)
DECLARE FUNCTION QPRATE# (Pv#, Fv#, Term)
DECLARE FUNCTION QPROUND$ (Number#, Places)
DECLARE FUNCTION QPSLN# (Cost#, Sal#, Life)
DECLARE FUNCTION QPSTD# (Array#())
DECLARE FUNCTION QPSUM# (Array#())
DECLARE FUNCTION QPSYD# (Cost#, Sal#, Life, Per)
DECLARE FUNCTION QPVAR# (Array#())


'==== Demonstration for determining mortgage/car payments

CLS
INPUT "Enter the value of the loan: ", Temp$
Pv# = VAL(Temp$)

INPUT "Enter the annual interest rate (if 8% enter .08): ", Temp$
Intr# = VAL(Temp$) / 12 '/12 because these function expect monthly interest

INPUT "Enter the number of months: ", Temp$
Term% = VAL(Temp$)

INPUT "Enter the balloon amount (or press Enter if none): ", Bal#

PRINT "Your monthly payment is"; QPPMT#(Pv#, Intr#, Term%, Bal#)
END


'---------- MATHEMATICAL FUNCTIONS AND QUICKPAK PROFESSIONAL EQUIVALENTS

'@ACOS(x)       Arc cosine of x (rad.)  -1 <= x <= +1
'   QPACOS#(x#) = pi / 2 - ATN(x# / SQR(1 - x# * x#))   ABS(x#) <> 1
'   QPACOS#(x#) = 1                                     x = 1
'   QPACOS#(x#) = pi                                    otherwise


'@ASIN(x)       Arc sine of x (rad.)  -1 <= x <= +1
'   QPASIN#(x#) = ATN(x# / SQR(1 - x# * x#))            ABS(x#) <> 1
'   QPASIN#(x#) = SGN(x#) * pi / 2                      otherwise


'@ATAN2(x,y)    4-quadrant arc tangent of y/x (rad.)
'   QPATAN2#(x#, y#) = SGN(y#) * pi / 2                 x = 0
'   QPATAN2#(x#, y#) = ATN(y# / x#)                     x > 0
'   QPATAN2#(x#, y#) = pi + ATN(y# / x#)                x < 0 & y >= 0
'   QPATAN2#(x#, y#) = -pi + ATN(y# / x#)               x < 0 & y <= 0


'@INT(x)        Integer part of x (-*- note Lotus' incorrect terminology)
'   use BASIC's FIX(x) to get the equivalent of what Lotus 123 does


'@LN(x)         Log of x base e
'   use BASIC's LOG(x)


'@LOG(x)        Log of x base 10
'   QPLOG10#(x#) = LOG(x#) / LOG(10)


'@PI            Value of pi
'   use the constant PI# = 3.14159265358979323846#
'or
'   use PI# = 4# * ATN(1#) to compute it


'@RAND          Random number 0-1
'   use BASIC's RND        (See RANDOMIZE function in QB manual)
'                          (also see QuickPak Rand function in FNOTHER.BAS)


'@ROUND(x,n)    x rounded to n decimal places
'   QPROUND$(Number#, Places%)



'----- FINANCIAL FUNCTIONS AND QUICKPAK PROFESSIONAL EQUIVALENTS

'Many of the Lotus financial functions involve annuities.  An annuity is
'simply a series of equal payments made at regular intervals of time.  It
'is a compound interest situation with regular payments.  When the payments
'are made at the beginning of the payment period, the annuity is called an
'"annuity due".  When payment is due at the end of the payment period it is
'an "ordinary annuity".

'where

        'fv#   = future value
        'pv#   = present value
        'pmt#  = payment per period
        'I!    = interest rate PER PERIOD in percent
        'intr# = I/100 (I)
        'term% = number of periods
        'prin# = principal (same as pv#)
        'bal#  = balloon payment (may be 0)


'NOTE: Several of the functions we have provided are not available even in
'      Lotus 123, and are identified below with a leading "*".
    

'A sinking fund annuity is most easily described as a savings fund designed
'to accumulate a predetermined amount of money on a specified date.

'@FV(pmt#, intr#, term%)      Future value of ordinary annuity (sinking fund)
'   QPFV#(pmt#, intr#, term%) = pmt# * ((1 + intr#)^ term% - 1) / intr#

'*@FVN(fv#, pmt#, intr#)      Term (number of payments) of a sinking fund
'   QPFVN#(fv#, pmt#, intr#) = LOG(fv# * intr# / pmt# + 1) / LOG(1 + intr#)

'*@FVP(fv#, intr#, term%)     Payment amount of a sinking fund
'   QPFVP#(fv#, intr#, term%) = fv# * intr# / ((1 + intr#)^ term% - 1)



'An example annuity due (future value) is the future value of a savings
'account with equal deposits made at the beginning of each period.

'*@FVD(pmt#, intr#, term%)    Future value of annuity due
'   QPFVD#(pmt#, intr#, term%) = _
'          pmt# * (1 + intr#) * ((1+ intr#)^ term% - 1) / intr#

'*@FVND(fv#, pmt#, intr#)     Term (number of payments) of an annuity due / FV
'   QPFVND#(fv#, pmt#, intr#) = _
'           LOG(fv# * intr# / pmt# + 1 + intr#) / LOG(1 + intr#) - 1

'*@FVPD(fv#, intr#, term%)    Payment amount of an annuity due/FV
'   QPFVPD#(fv#, intr#, term#) = _
'           fv# / ((1 + intr#) / intr# * (1 + intr#)^ term% - 1)



'When a sum of money is to be repaid with interest in fixed payments for a
'specified number of periods (such as with a home mortgage), it is called
'an ordinary annuity.  A balloon payment may be associated with this type
'of annuity.
'
'@PMT(pv#, intr#, term%)      Loan payment (ordinary annuity)
'   QPPMT#(pv#, intr#, term%, bal#) = _
'         (pv# - bal# * (1+intr#)^ -term%) / ((1 - (1+intr#)^ -term%) / intr#)

'@PV(pmt#, intr#, term%)      Present value of an ordinary annuity
'   QPPV#(pmt#, intr#, term%, bal#) = _
'         pmt# * (1 - (1 + intr#)^ -term%) / intr# + bal# * (1 + intr#)^ -term%

'*@PVN(pmt#, intr#, pv#)      Term (number of payments) of an ordinary annuity
'   QPPVN#(pmt#, intr#, pv#, bal#) = _
'          LOG((pmt# - intr# * bal#) / (pmt# - intr# * pv#)) / LOG(1 + intr#)



'In order to find the present value of a lease which will involve fixed
'payments at the beginning of each payment period, use these annuity due
'relationships.

'*@PMTD(pv#, int# ,term%)     Lease payment (annuity due)
'   QPPMTD#(pv#, intr#, term%, bal#) = _
'          (pv# - bal# * (1 + intr#)^ -term%) / (1 + intr#) / _
'          ((1 - (1 + intr#)^ -term%) / intr#)

'*@PVD(pmt#, intr#, term%)    Present value of annuity due
'   QPPVD#(pmt#, intr#, term%, bal#) = _
'          pmt# * (1+intr#) * (1-(1+intr#)^ -term%) / _
'          intr# + bal# * (1+intr#)^ -term%

'*@PVND(pmt#, intr#, pv#)     Term (number of payments) of an annuity due
'   QPPVND#(pmt#, intr#, pv#, bal#) = _
'           LOG((pmt# * (1 + intr#) / intr# - bal#) / _
'           (pmt# * (1 + intr#) / intr# - pv#)) / LOG(1 + intr#)



'In order to find the future value of a savings account drawing compound
'interest, use the FCINT function
'
'*@CINT(pv#, intr#, term%)    Compounded interest
'   QPCINT#(pv#, intr#, term%) = pv# * (1 + intr#)^ term%



'To determine the number of compounding periods it will take an
'investment to grow to a pre-determined value, use the FCTERM function
'
'@CTERM(intr#, fv#, pv#)      Compounded term of investment
'                             Note: Interest Rate (intr#) must be in decimal
'                                   form.  For example, the monthly rate of
'                                   10% per year is (10/100)/12 or .008333
'
'   QPCTERM#(pv#, fv#, intr#) = LOG(fv# / pv#) / LOG(1 + intr#)



'The periodic interest rate required for an investment to grow to a pre-
'determined value in a specified time is:

'@RATE(fv#, pv#, term%)       Rate of investment
'   QPRATE#(pv#, fv#, term%) = (fv# / pv#)^ 1 / term% - 1



'The IRS allows depreciation of various assets using some of the methods
'listed below (depending on the type and life of the asset).

'@DDB(cost#, salvage#, life%, period%)
'Double declining balance depreciation for the year, with 1<=year<=life
'   QPDDB#(cost#, sal#, life%, per%, m!) = _
'          m! * cost# / life%^ per% * (life% - 2)^ (per% - 1)
'
'   where "m" is the depreciation multiplier ie.
'          m = 2   - Double Declining Balance
'          m = 1.5 - 150% Declining Balance
'          m = 1   - Simple Declining Balance
'
'Adjustments are made to the formula to insure that the total depreciation
'does not exceed total cost less salvage value.

'@SLN(cost#, salvage#, life%) Straight-line depreciation for one period
'   QPSLN#(cost#, sal#, life%) = (cost# - sal#) / life%

'@SYD(cost#, salvage#, life%, period%)
'Sum-of-years'-digits depreciation for the year, with 1<=year<=life
'   QPSYD#(cost#, sal#, life%, per%) = _
'         (cost# - sal#) * (life% - per% + 1) / (life% * (life% + 1) / 2)



'@IRR(guess#, range#()) Internal rate of return.  This function is seeded
'                       by giving it an initial IRR rate (guess).  The
'                       algorithm first brackets the correct IRR and then
'                       converges on the final IRR by a halving method.
'                       Convergence ends when a given degree of accuracy
'                       is reached.
'
'   QPIRR#(intr#,Array#())



'@NPV(intr#, range#())  Net present value of future cash flows.  If the
'                       initial flow is NOT an outflow, enter zero as the
'                       first value in Array#().  This will give the PV of
'                       the dollar flow.
'
'   QPNPV#(intr#,Array#())



'----- STATISTICAL FUNCTIONS AND QUICKPAK PROFESSIONAL EQUIVALENTS

'@AVG(list)             Average of values in list
'   QPAVG#(Array#()) = QPSUM#(Array#()) / QPCOUNT%(Array#())

'@COUNT(list)           Number of entries
'   QPCOUNT%(Array#()) = UBOUND(Array#, 1) - LBOUND(Array#, 1) + 1

'@MAX(list)             Maximum value in list
'   QPMAX#(Array#())

'@MIN(list)             Minimum value in list
'   QPMIN#(Array#())

'@STD(list)             Population standard deviation of items in list
'   QPSTD#(Array#())

'@SUM(list)             Sum of the values in list
'   QPSUM#(Array#())

'@VAR(list)             Population variance of values in list
'   QPVAR#(Array#())

FUNCTION QPACOS# (X#) STATIC

    IF ABS(X#) <> 1# THEN
       QPACOS# = 1.570796326794897# - ATN(X# / SQR(1# - X# * X#))
    ELSEIF X# = 1# THEN
       QPACOS# = 0#
    ELSE
       QPACOS# = 3.141592653589793#
    END IF

END FUNCTION

FUNCTION QPASIN# (X#) STATIC

    IF ABS(X#) <> 1# THEN
       QPASIN# = ATN(X# / SQR(1# - X# * X#))
    ELSE
       QPASIN# = SGN(X#) * 1.570796326794897#
    END IF

END FUNCTION

FUNCTION QPATAN2# (X#, Y#) STATIC

    IF X# = 0# THEN
       QPATAN2# = SGN(Y#) * 1.570796326794897#
    ELSEIF X# > 0# THEN
       QPATAN2# = ATN(Y# / X#)
    ELSEIF Y# >= 0# THEN
       QPATAN2# = 3.141592653589793# + ATN(Y# / X#)
    ELSE
       QPATAN2# = -3.141592653589793# + ATN(Y# / X#)
    END IF

END FUNCTION

'External functions required:  QPSUM#()
'                              QPCOUNT%()
'
FUNCTION QPAVG# (Array#()) STATIC
    QPAVG# = QPSUM#(Array#()) / QPCOUNT%(Array#())
END FUNCTION

FUNCTION QPCINT# (Pv#, Intr#, Term%) STATIC
    QPCINT# = Pv# * (1# + Intr#) ^ Term%
END FUNCTION

FUNCTION QPCOUNT% (Array#()) STATIC
    QPCOUNT% = UBOUND(Array#, 1) - LBOUND(Array#, 1) + 1
END FUNCTION

FUNCTION QPCTERM# (Pv#, Fv#, Intr#) STATIC
    QPCTERM# = LOG(Fv# / Pv#) / LOG(1# + Intr#)
END FUNCTION

FUNCTION QPDDB# (Cost#, Sal#, Life%, Per%, M!) STATIC

    FOR A% = 1 TO Per%
        Depper# = Cost# * M! / Life%
        Cost# = Cost# - Depper#
        IF Depper# > 0# AND Cost# < Sal# THEN
           Depper# = Depper# - Sal# + Cost#
           Cost# = 0#
        END IF
    NEXT

    QPDDB# = Depper#
'   equivalent: QPDDB# = M! * Cost# / Life% ^ Per% * (Life% - 2) ^ (Per% - 1)

END FUNCTION

FUNCTION QPFV# (Pmt#, Intr#, Term%) STATIC
    QPFV# = Pmt# * ((1# + Intr#) ^ Term% - 1) / Intr#
END FUNCTION

FUNCTION QPFVD# (Pmt#, Intr#, Term%) STATIC
    QPFVD# = Pmt# * (1# + Intr#) * ((1# + Intr#) ^ Term% - 1) / Intr#
END FUNCTION

FUNCTION QPFVN# (Fv#, Pmt#, Intr#) STATIC
    QPFVN# = LOG((Fv# * Intr#) / Pmt# + 1#) / LOG(1# + Intr#)
END FUNCTION

FUNCTION QPFVND# (Fv#, Pmt#, Intr#) STATIC
    QPFVND# = LOG(Fv# * Intr# / Pmt# / (1# + Intr#) + 1#) / LOG(1# + Intr#)
END FUNCTION

FUNCTION QPFVP# (Fv#, Intr#, Term%) STATIC
    QPFVP# = Fv# * Intr# / ((1# + Intr#) ^ Term% - 1)
END FUNCTION

FUNCTION QPFVPD# (Fv#, Intr#, Term%) STATIC
    QPFVPD# = Fv# * Intr# / (1# + Intr#) / ((1# + Intr#) ^ Term% - 1#)
END FUNCTION

FUNCTION QPIRR# (Intr#, Array#()) STATIC

    Hi% = UBOUND(Array#, 1)
    Lo% = LBOUND(Array#, 1)

    Inv1# = ABS(Array#(1)) * -1         'assure that 1st number is neg

    Rate0# = Intr#
'         ********   Bracket IRR   ********
    Rate1# = Rate0#
 
    RateX# = Rate1#
    Cx% = 0
    E1% = 0: E2% = 0                    'bracket control variables

Bracket:      
    Temp# = Inv1#                       'initialize
    GOSUB IRRCalcB                      'Calc & return NPV (Temp#)

    Cx% = Cx% + 1
    IF Cx% = 1 THEN
       NPV0# = Temp#                    'NPV of 1st trial
       IF ABS(NPV0#) < .01# GOTO EndIRRFnc
    END IF

'----- additional NPV trials to bracket correct IRR
  
    IF Temp# > 0 THEN
       Rate1# = RateX#
       E1% = 1
       IF E1% + E2% = 3 GOTO ConvergeA
       RateX# = RateX# * 1.05#
       GOTO Bracket
    ELSE
       Rate2# = RateX#
       E2% = 2
       IF E1% + E2% = 3 GOTO ConvergeA
       RateX# = RateX# * .95#
       GOTO Bracket
    END IF

'      ********   Converge on IRR to given accuracy   ********
ConvergeA:                              'resolve to .0001 percent error
                                        '  by halving method
    CZ% = 0
    RateX# = (Rate1# + Rate2#) / 2

ConvergeB:
    CZ% = CZ% + 1               'count iterations (optional if you care)
    GOSUB IRRCalcA

    IF ABS((Rate1# - Rate2#) / Rate1#) < .0001# GOTO EndIRRFnc

    IF Temp# > 0 THEN
       Rate1# = RateX#
       RateX# = (RateX# + Rate2#) / 2#
       GOTO ConvergeB
    ELSE
       Rate2# = RateX#
       RateX# = (RateX# + Rate1#) / 2#
       GOTO ConvergeB
    END IF

IRRCalcA:
    IF ABS(RateX#) < .0000005# THEN     'check for zero (or equivalent)
       RateX# = 0#
       GOTO EndIRRFnc
    END IF

IRRCalcB:
    Temp# = Inv1#                       'initialize with investment
    FOR X% = 2 TO Hi%                   'discount future dollar stream
      Temp# = Temp# + (Array#(X%) / (1# + RateX# / 100#) ^ (X% - 1))
    NEXT
RETURN                                  'return with NPV at RateX#

EndIRRFnc:
    QPIRR# = RateX#
    'PRINT "IRR Iterations:"; cz        'unREM to see this

END FUNCTION

FUNCTION QPLOG10# (X#) STATIC
    QPLOG10# = LOG(X#) / LOG(10#)
END FUNCTION

FUNCTION QPMAX# (Array#()) STATIC

    Lo% = LBOUND(Array#, 1)             'get the lowest subscript
    Hi% = UBOUND(Array#, 1)             'and the highest
    'QPMAX# = MaxD#(SEG Array#(Lo%), Hi% - Lo% + 1)  'use the .asm version here

END FUNCTION

FUNCTION QPMIN# (Array#()) STATIC

    Lo% = LBOUND(Array#, 1)             'get the range of subscripts
    Hi% = UBOUND(Array#, 1)             'and the highest
    'QPMIN# = MinD#(SEG Array#(Lo%), Hi% - Lo% + 1)    'use the .asm version here

END FUNCTION

FUNCTION QPNPV# (Intr#, Array#()) STATIC

    Hi% = UBOUND(Array#, 1)
    Lo% = LBOUND(Array#, 1)

    Temp# = ABS(Array#(1)) * (-1)             'assure that 1st number is neg
  
    FOR X% = 2 TO Hi%                         'discount future dollar stream
      Temp# = Temp# + (Array#(X%) / (1# + Intr# / 100#) ^ (X% - 1))
    NEXT X%

    QPNPV# = Temp#                            'set returned value

END FUNCTION

FUNCTION QPPMT# (Pv#, Intr#, Term%, Bal#) STATIC

    Temp# = (1# + Intr#) ^ -Term%
    QPPMT# = (Pv# - Bal# * Temp#) / ((1# - Temp#) / Intr#)

END FUNCTION

FUNCTION QPPMTD# (Pv#, Intr#, Term%, Bal#) STATIC

    Temp# = (1# + Intr#) ^ -Term%
    QPPMTD# = (Pv# - Bal# * Temp#) / ((1# + Intr#) * (1# - Temp#) / Intr#)

END FUNCTION

FUNCTION QPPV# (Pmt#, Intr#, Term%, Bal#) STATIC

    Temp# = (1# + Intr#) ^ -Term%
    QPPV# = Pmt# * (1# - Temp#) / Intr# + Bal# * Temp#

END FUNCTION

FUNCTION QPPVD# (Pmt#, Intr#, Term%, Bal#) STATIC

    Temp# = (1# + Intr#) ^ -Term%
    QPPVD# = Pmt# * (1# + Intr#) * (1# - Temp#) / Intr# + Bal# * Temp#

END FUNCTION

FUNCTION QPPVN# (Pmt#, Intr#, Pv#, Bal#) STATIC
    QPPVN# = LOG((Pmt# - Intr# * Bal#) / (Pmt# - Intr# * Pv#)) / LOG(1# + Intr#)
END FUNCTION

FUNCTION QPPVND# (Pmt#, Intr#, Pv#, Bal#) STATIC

    Temp# = Pmt# * (1# + Intr#) / Intr#
    QPPVND# = LOG((Temp# - Bal#) / (Temp# - Pv#)) / LOG(1# + Intr#)

END FUNCTION

FUNCTION QPRATE# (Pv#, Fv#, Term%) STATIC
    QPRATE# = (Fv# / Pv#) ^ (1 / Term%) - 1
END FUNCTION

'********** QPROUND
'
'This function accepts a double precision value and a number of decimal
'places to round it to, and returns the answer in a string.  The number
'must be processed as a string because many double precision values can
'not be represented accurately any other way.  To prove this, enter the
'following line into the QuickBASIC 4 editor and watch what happens:
'
'    X# = .0691#
'
'
FUNCTION QPROUND$ (amount#, Places%) STATIC

'External routines required:  ASCII%
'                             FUsing

    amount$ = STR$(amount#)                     'first convert into a string
   
    '10-15-91: The four lines below that are now comments have been replaced
    'with the three lines that follow.  This makes QPROUND$ nearly 7 times
    'faster.  Thanks to Peter Alachi for this improvement!

    'Lead% = 1                          'allow one leading digit
    'DO WHILE ABS(Amount#) + .000001# >= 10# ^ Lead%
    '   Lead% = Lead% + 1               'the .000001# avoids a QB bug w/80x87
    'LOOP                            

    Lead = INSTR(LTRIM$(amount$), ".")  'get the number of leading digits
    IF Lead > 1 THEN Lead = Lead - 1
    IF Lead = 0 THEN Lead = LEN(LTRIM$(amount$))

    Dec$ = MID$(".", ABS(Places% = 0) + 1)      'make a "." if needed
    Plus$ = MID$("+", SGN(amount#) + 2)         'make a "+" if needed
    Mask$ = Plus$ + STRING$(Lead% + 1, "#") + Dec$ + STRING$(Places%, "#") '+1
    Mask$ = FUsing$(amount$, Mask$)             'let Chris do the dirty work

    IF ASCII%(Mask$) = 48 THEN                  'if there's a leading zero
       Mask$ = MID$(Mask$, 2)                   'strip it
    END IF

    QPROUND$ = LTRIM$(Mask$)                    'assign the function

END FUNCTION

FUNCTION QPSLN# (Cost#, Sal#, Life%) STATIC
    QPSLN# = (Cost# - Sal#) / Life%
END FUNCTION

'External functions required:  QPVAR#()
'                              QPSUM#() used by QPVAR#()
'
FUNCTION QPSTD# (Array#()) STATIC
    QPSTD# = SQR(QPVAR#(Array#()))
END FUNCTION

FUNCTION QPSUM# (Array#()) STATIC

    Lo% = LBOUND(Array#, 1)
    Hi% = UBOUND(Array#, 1)

    S# = 0#
    FOR X% = Lo% TO Hi%
        S# = S# + Array#(X%)
    NEXT
    QPSUM# = S#

END FUNCTION

FUNCTION QPSYD# (Cost#, Sal#, Life%, Per%) STATIC
    QPSYD# = (Cost# - Sal#) * (Life% - Per% + 1) / (Life% * (Life% + 1) / 2#)
END FUNCTION

'External functions required:  QPSUM#()
'
FUNCTION QPVAR# (Array#()) STATIC

    Hi% = UBOUND(Array#, 1)
    Lo% = LBOUND(Array#, 1)

    NumItems% = Hi% - Lo% + 1
    Average# = QPSUM#(Array#()) / NumItems%
    S# = 0#

    FOR X% = Lo% TO Hi%
        Temp# = (Array#(X%) - Average#) ^ 2#   'individual deviations squared
        S# = S# + Temp#
    NEXT

    QPVAR# = S# / NumItems%

END FUNCTION

