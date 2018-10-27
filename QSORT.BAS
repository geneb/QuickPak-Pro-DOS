'********** QSort.Bas - sort routine algorithm demonstration

'Copyright (c) 1988 Ethan Winer, with special thanks to Eric Klien

'This program illustrates the algorithm used by the QuickPak Professional
'assembler string sorts, and is provided solely for its educational value.
'Though it is set up to sort a single precision numeric array, it would
'be simple to modify for use with any variable type.  The demo illustrates
'how the sorting can be limited to only a portion of an array.


DEFINT A-Z
DECLARE SUB QSort (Array!(), StartEl, NumEls)

CLS
RANDOMIZE TIMER         'this generates a fresh series of numbers each time

ArrayLo = 1             'set the array bounds
ArrayHi = 20

DIM Array!(ArrayLo TO ArrayHi)
FOR X = ArrayLo TO ArrayHi      'make up some test numbers
    Array!(X) = RND(1) * 999 + 1
NEXT

FirstEl = 10                    'sort only this portion of the array
NumEls = 6                      'the actual number of elements to be sorted

FOR X = ArrayLo TO ArrayHi      'first print them before sorting
    IF X >= FirstEl AND X <= FirstEl + NumEls - 1 THEN PRINT "==>";
    PRINT TAB(5); USING "###.##"; Array!(X)
NEXT

CALL QSort(Array!(), FirstEl, NumEls)

LOCATE 1
FOR X = ArrayLo TO ArrayHi      'now print them after sorting
    LOCATE , 20
    IF X >= FirstEl AND X <= FirstEl + NumEls - 1 THEN PRINT "==>";
    LOCATE , 25
    PRINT USING "###.##"; Array!(X)
NEXT

SUB QSort (Array!(), StartElement, NumOfElements) STATIC

    REDIM QStack(50)     'create Stack (use 500 when sorting large arrays)

    S = 1               'initialize work variables
    F = StartElement
    L = StartElement + NumOfElements - 1

L1:
    Temp! = Array!((L + F) \ 2)         'seek midpoint
    I = F
    J = L

L2:
    WHILE Array!(I) < Temp!: I = I + 1: WEND    'use > for descending
    WHILE Array!(J) > Temp!: J = J - 1: WEND    'use < for descending
    IF I > J GOTO L3
    IF I < J THEN SWAP Array!(I), Array!(J)
    I = I + 1: J = J - 1
    IF I <= J GOTO L2

L3:
    IF I < L THEN
       QStack(S) = I             'Push I, L
       QStack(S + 1) = L
       S = S + 2
    END IF

    L = J
    IF F < L GOTO L1
    IF S = 1 GOTO L4
    S = S - 2                   'Pop L, F
    F = QStack(S)
    L = QStack(S + 1)
    GOTO L1

L4:
    ERASE QStack                 'delete the temporary stack array

END SUB

