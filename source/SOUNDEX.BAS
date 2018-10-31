'********** SOUNDEX.BAS - demonstrates comparing strings based on thier sound

'Copyright (c) 1990 Ethan Winer

DEFINT A-Z
DECLARE FUNCTION Soundex$ (Work$)

LINE INPUT "Enter any string : ", String1$
LINE INPUT "Enter another one: ", String2$

First$ = Soundex$(String1$)
PRINT "Here's the Soundex code for "; String1$; " : "; First$
Second$ = Soundex$(String2$)
PRINT "And here's the code for "; String2$; " : "; Second$

IF First$ = Second$ THEN
   PRINT "They sound alike"
ELSE
   PRINT "They do not sound alike"
END IF

