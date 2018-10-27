'********** BIGPRINT.BAS - shows how to use APrint to create big letters

'Copyright (c) 1988 Ethan Winer


'This is just a silly demo showing how to print big letters.  You could
'easily use Search/Replace to change the block characters used below to
'some of the other available characters such as CHR$(177), 178, or 219.

DEFINT A-Z
DECLARE SUB APrint0 (BYVAL Address, NumEls, StartChar, NumChars, Colr)

CLS
DIM Title$(6)           'leave 0 and 6 for the border
FOR X = 1 TO 5
  READ Title$(X)
NEXT
DATA "      °°°°°  °   °  °°°  °°°°°     °°°  °°°°°     °°°°   °°°   °°°°"
DATA "        °    °   °   °   °          °   °         °   °   °   °    "
DATA "        °    °°°°°   °    °°°       °    °°°      °°°°    °   ° °°"
DATA "        °    °   °   °       °      °       °     °   °   °   °   °"
DATA "        °    °   °  °°°  °°°°°     °°°  °°°°°     °°°°   °°°   °°°"
                                     
CALL APrint0(VARPTR(Title$(0)), 7, 1, 74, 78)

