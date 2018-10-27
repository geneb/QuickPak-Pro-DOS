'********** InsertT.Bas - demos InsertT and DeleteT

'Copyright (c) 1988 Ethan Winer

'This demo requires starting QuickBASIC 4.0 with the /AH option

DEFINT A-Z
TYPE FLen
   Member AS SINGLE     'or INTEGER or LONG or STRING * n or whatever
END TYPE

DECLARE SUB InsertT (SEG Element AS FLen, ElSize, NumEls)
DECLARE SUB DeleteT (SEG Element AS FLen, ElSize, NumEls)

CLS
ASize = 5000
StartEl = 3

'ElSize can also use a code for the type of array being operated on:
'
'  -1 = integer
'  -2 = single precision } <--- these two are interchangeable, and it
'  -3 = long integer     } <--- doesn't matter which you use
'  -4 = double precision
'  +N = TYPE array or fixed-length string with a variable size of N

ElSize = -2
DIM Array(ASize) AS FLen
NumEls = UBOUND(Array, 1) - StartEl     'insert/delete to the end of the array

FOR X = 0 TO ASize
    Array(X).Member = X         'use STR$(X) for fixed-length strings
NEXT

PRINT TAB(5); "Original"; TAB(30); "After Inserting"; TAB(60); "After Deleting"
PRINT
FOR X = 1 TO 10
    PRINT TAB(5); X; Array(X).Member
NEXT
PRINT
FOR X = 4991 TO 5000
    PRINT TAB(5); X; Array(X).Member
NEXT

InsertT Array(StartEl), ElSize, NumEls  'unREM one of these if you'd like

LOCATE 3
FOR X = 1 TO 10
    LOCATE , 30
    PRINT X; Array(X).Member
NEXT
PRINT
FOR X = 4991 TO 5000
    LOCATE , 30
    PRINT X; Array(X).Member
NEXT

DeleteT Array(StartEl), ElSize, NumEls

LOCATE 3
FOR X = 1 TO 10
    LOCATE , 60
    PRINT X; Array(X).Member
NEXT
PRINT
FOR X = 4991 TO 5000
    LOCATE , 60
    PRINT X; Array(X).Member
NEXT

