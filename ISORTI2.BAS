'********** ISortI2.Bas - sorts a random integer array from any base

'Copyright (c) 1988 Ethan Winer


'Indexed sorting with arrays that do not begin at element zero can appear
'confusing at first.  Therefore, this demonstration is included to show
'how a main array with a base of zero may be sorted starting at element 15,
'while the index array is based at element 1.
'
'Additional information about indexed sorting is in the ISORTSTR.BAS demo
'program, and another example program is shown in ISORTI.BAS.


DEFINT A-Z
DECLARE SUB AddInt (SEG AElement, Value, NumEls)
DECLARE SUB InitInt (SEG AElement, StartValue, NumEls)
DECLARE SUB ISortI (SEG Element, SEG IndexElement, NumEls, Direction)

CLS
CLEAR , , 1500    'ISort needs the extra stack space - this program works
		  '  without the Clear command up to a few hundred elements,
		  '  but you will need it when sorting large arrays.

Start = 15        'specify start of the range to sort,
NumEls = 10       '  the number of elements to be included,
Size = 2000       '  and the total size of the array

REDIM Array(0 TO Size)          'allocate an integer array
REDIM Index(1 TO NumEls)        'you MUST dimension this integer array

FOR X = 0 TO Size               'fill the entire array with random junk
    Array(X) = RND(1) * 1200
NEXT

PRINT : PRINT

PRINT "Ascending or Descending (A/D)? ";
DO
   X$ = UCASE$(INKEY$)
LOOP UNTIL LEN(X$)
PRINT X$
IF X$ = "D" THEN Direction = 1

X! = TIMER                              'so we can time the sort

InitInt Index(1), 0, NumEls             'initialize the index array

ISortI Array(Start), Index(1), NumEls, Direction      'sort the index

AddInt Index(1), Start, NumEls          'add Start to every element (needed
					'  unless starting at element zero)
Y! = TIMER - X!
PRINT USING "Time: ##.## Seconds"; Y!;
PRINT

PRINT "Press any key to display sorted array ";
CALL WaitKey

LOCATE 25, 1, 0
PRINT "Press any key to pause";
LOCATE 8, 1

FOR X = Start TO Start + NumEls - 1
'-- here's the indexing part:
    PRINT X, Array(Index(X - Start + 1))
    IF INKEY$ <> "" THEN
       CALL WaitKey                     'pause on any keypress
    END IF
NEXT

