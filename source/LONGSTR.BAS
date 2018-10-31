'********** LONGSTR.BAS -- determines the longest element in an array quickly

'Copyright (c) 1990 Ethan Winer


DEFINT A-Z
DECLARE FUNCTION LongestStr% (Array$())

DIM Array$(3 TO 240)
FOR X = 3 TO 240
    Array$(X) = SPACE$(RND * 100 + 1)
NEXT
PRINT "The longest string in this array is:"; LongestStr%(Array$())

