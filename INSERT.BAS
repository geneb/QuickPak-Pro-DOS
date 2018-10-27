'********** Insert.Bas - inserts a string into an array

'Copyright (c) 1988 Ethan Winer

'rough timing on an 8MHz AT:  0.06 seconds to insert/delete 3000 elements


DEFINT A-Z
DECLARE SUB InsertStr (BYVAL Address, Inserted$, Size)
DECLARE SUB DeleteStr (BYVAL Address, Size)

CLS
PRINT TAB(15); "Before:"; TAB(50); "After:"

REDIM Array$(10)
FOR X = 0 TO 10
    Array$(X) = "Element Number" + STR$(X)
    LOCATE X + 3, 10
    PRINT Array$(X)
NEXT
PRINT

Inserted$ = "This is inserted"
PRINT "Inserted$ = "; CHR$(34); Inserted$; CHR$(34)

'----- Inserted$ goes in Array$(3), do seven elements (4 through 10 inclusive)

InsertStr VARPTR(Array$(3)), Inserted$, 7

FOR X = 0 TO 10
    LOCATE X + 3, 45
    PRINT Array$(X)
NEXT

PRINT
LOCATE , 45, 1
PRINT "Inserted$ = "; CHR$(34); Inserted$; CHR$(34)
PRINT
PRINT "This proves we didn't corrupt BASIC's string heap:  ";
PRINT "Free memory ="; FRE("")
LOCATE 25, 1
PRINT "Press a key to see the Delete demo: ";
CALL WaitKey

CLS
PRINT TAB(15); "Before:"; TAB(50); "After:"

REDIM Array$(10)
FOR X = 0 TO 10
    Array$(X) = "Element Number" + STR$(X)
    LOCATE X + 3, 10
    PRINT Array$(X)
NEXT
PRINT


'----- we'll delete Array$(3), adjust seven elements (4 through 10 inclusive)

DeleteStr VARPTR(Array$(3)), 7

FOR X = 0 TO 10
    LOCATE X + 3, 45
    PRINT Array$(X)
NEXT

PRINT
PRINT
PRINT
PRINT "This proves we didn't corrupt BASIC's string heap:  ";
PRINT "Free memory ="; FRE("")

