'********** ISortI.Bas

'Copyright (c) 1988 Ethan Winer


'Indexed sorting with arrays that do not begin at element zero can appear
'confusing at first.  This demonstration is included to show how arrays
'that start with element 1 are sorted and accessed.
'
'Additional information about indexed sorting is in the ISORTSTR.BAS demo
'program, and another example program is shown in ISORTI2.BAS.


DEFINT A-Z
DECLARE SUB AddInt (SEG AElement, Value, NumEls)
DECLARE SUB InitInt (SEG AElement, StartValue, NumEls)
DECLARE SUB ISortI (SEG element, SEG IndexElement, NumEls, Direction)

CLS
CLEAR , , 1500    'ISort needs the extra stack space - this program works
		  '  without the Clear command up to a few hundred elements,
		  '  but you will need it when sorting large arrays.

Start = 1         'specify start of the range to sort
Size = 2000       'and the number of elements to include

REDIM Array(1 TO Size)  'allocate an integer array for the main sorted data
REDIM Index(1 TO Size)  'you MUST dimension this integer array
   
FOR X = 1 TO Size
    Array(X) = RND(1) * 1200    'fill the array with random numbers
NEXT

PRINT "Ascending or Descending (A/D)? ";
DO
   X$ = UCASE$(INKEY$)
LOOP UNTIL LEN(X$)
PRINT X$
IF X$ = "D" THEN Direction = 1

PRINT : PRINT
X! = TIMER                              'so we can time the sort

InitInt Index(Start), 0, Size           'initialize the array (base zero)

ISortI Array(Start), Index(Start), Size, Direction      'sort the index

AddInt Index(Start), 1, Size            'add one to every element (needed
					'  unless starting at element zero)

X! = TIMER - X!
PRINT USING "Time: ##.## Seconds"; X!;
PRINT

PRINT "Press any key to display sorted array ";
CALL WaitKey

LOCATE 25, 1, 0
PRINT "Press any key to pause";
LOCATE 8, 1

FOR X = 1 TO Size
    PRINT X, Array(Index(X))            'here's the indexing part
    IF INKEY$ <> "" THEN
       CALL WaitKey                     'pause on any keypress
    END IF
NEXT

