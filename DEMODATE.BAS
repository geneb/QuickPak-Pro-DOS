'********** DEMODATE.BAS

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z
DECLARE FUNCTION Date2Num% (Dat$)
DECLARE FUNCTION Num2Date$ (Number)
DECLARE FUNCTION Num2Day% (Days)
DECLARE FUNCTION DayName$ (Days)

CLS
INPUT "Enter a date string as MM-DD-YYYY: ", Dat$

'Actually, Date2Num will accept MMDDYY, MMDDYYYY, MM-DD-YY, MM/DD/YYYY,
'and so forth, but we want to show how to validate a date.  To do this,
'there must be some control over the incoming date format.

PRINT
Days = Date2Num%(Dat$)
NewDat$ = Num2Date$(Days)

PRINT "The equivalent QuickPak Date Number is:"; Days
PRINT "                The day of the week is: "; DayName$(Num2Day%(Days))
PRINT "After conversion back to a Date format: "; NewDat$

IF NewDat$ <> Dat$ THEN
   PLAY "L32O3ECEC"
   PRINT
   PRINT NewDat$; " is not the same as the date entered!"
END IF

