'********** WeekDay.Bas - calculates the day of the week

'Copyright (c) 1987 Ethan Winer


DEFINT A-Z
DECLARE FUNCTION WeekDay% (D$)

CLS

DIM Day$(7)
FOR X = 1 TO 7
    READ Day$(X)
NEXT

LINE INPUT "Enter a date (MMDDYY): "; D$
PRINT

Day = WeekDay%(D$)
IF Day = 0 THEN PRINT "Invalid date": END
PRINT "That date is a "; Day$(Day)

Day = WeekDay%(LEFT$(DATE$, 2) + MID$(DATE$, 4, 2) + RIGHT$(DATE$, 2))
PRINT "And today is a "; Day$(Day)

DATA "Sunday",   "Monday", "Tuesday", "Wednesday"
DATA "Thursday", "Friday", "Saturday"

