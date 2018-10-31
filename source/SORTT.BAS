'********** SortT.Bas - demonstrates the QuickPak TYPE array sort

'Copyright (c) 1988 Crescent Software


DEFINT A-Z
TYPE Struct
   Zip AS INTEGER
   Who AS STRING * 1
   Junk AS STRING * 1
END TYPE

DECLARE SUB SortT (SEG Element AS Struct, NumEls, Dir, SSize, MOff, MSize)

CLEAR , , 2000          'the sort routines need the extra stack space
CLS


Start = 1               'start at array element 1
Size = 500              'the size (in elements) of the array
Dir = 0                 'sort direction - use anything else for descending
SSize = 4               'total size of each TYPE element
MOff = 0                'offset into the TYPE for the key element
MSize = -1              'size of the key element - coded as follows:
                        '   -1 = integer
                        '   -2 = long integer   
                        '   -3 = single precision
                        '   -4 = double precision
                        '   +N = TYPE array/fixed-length string of length N

REDIM Array(1 TO Size) AS Struct

FOR X = 1 TO Size
    Array(X).Zip = RND(1) * 32000 - RND(1) * 32000
    Array(X).Who = CHR$(X MOD 26 + 65)
'   PRINT Array(X).Zip, Array(X).Who    'unREM to see the array being created
NEXT

PRINT "Sorting . . ."

T! = TIMER                              'time the sort
SortT Array(Start), Size, Dir, SSize, MOff, MSize
T1! = TIMER - T!

LOCATE 1, 1
PRINT USING "##.## seconds to sort" + STR$(Size) + " elements"; T1!
PRINT "Press any key to view the sorted data"
WHILE INKEY$ = "": WEND
LOCATE 25
PRINT "Press any key to pause/restart";
VIEW PRINT 2 TO 24      'protect the top and bottom lines of the screen

FOR X = 1 TO Size
    PRINT Array(X).Zip, Array(X).Who
    IF LEN(INKEY$) THEN
       WHILE INKEY$ = "": WEND
    END IF
NEXT

FOR X = 2 TO Size               'this is for testing purposes only
    IF Dir = 0 THEN
       IF Array(X).Zip < Array(X - 1).Zip THEN BadSort = BadSort + 1
    ELSE
       IF Array(X).Zip > Array(X - 1).Zip THEN BadSort = BadSort + 1
    END IF
NEXT
PRINT
PRINT BadSort; "elements were sorted incorrectly"

