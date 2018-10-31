'********* DATE2DAY.BAS - finds the day of the week number from a Date String

'Copyright (c) 1987 Donald R. Malin
'Copyright (c) 1987 Crescent Software

'Caller passes a Date String in the form MMDDYY or MMDDYYYY, and this
'subprogram returns a day of the week number (1-7), where 1 = Sunday.

DECLARE FUNCTION Date2Day% (Dat$)
DECLARE FUNCTION Date2Num% (Dat$)
DECLARE FUNCTION Num2Day% (Days%)

FUNCTION Date2Day% (Dat$) STATIC
    Date2Day% = Num2Day%(Date2Num%(Dat$))
END FUNCTION

