'********** SortI.Bas - demo


DEFINT A-Z

DECLARE SUB SortI (SEG Element, NumElements, Direction)

CLEAR , , 2000          'SortInt needs the extra stack space
CLS

RANDOMIZE TIMER         'start with new random numbers each time
Start = 0               'start at element 0
Size = 2000             'whatever size you want
Dir = 0                 'use anything else for descending

REDIM Array(Size)
ModFactor = Size \ 100  'sample a portion for printing

FOR X = 0 TO Size
    Array(X) = RND(1) * 32000 - RND(1) * 32000
    IF X MOD ModFactor = 0 THEN PRINT Array(X);
NEXT

PRINT : PRINT : PRINT "Sorting . . ."

T! = TIMER                              'time the sort
SortI Array(Start), Size + 1, Dir     'do the sort
T1! = TIMER - T!

LOCATE CSRLIN - 1, 1                    'save space on the screen
PRINT USING "##.## seconds to sort" + STR$(Size) + " elements"; T1!;
PRINT " - press a key:"
WHILE INKEY$ = "": WEND

PRINT
FOR X = 1 TO Size
    IF Dir = 0 THEN
       IF Array(X) < Array(X - 1) THEN BadSort = BadSort + 1
    ELSE
       IF Array(X) > Array(X - 1) THEN BadSort = BadSort + 1
    END IF
    IF X MOD ModFactor = 0 THEN PRINT Array(X);
NEXT

PRINT : PRINT
PRINT BadSort; "elements were sorted incorrectly.";

