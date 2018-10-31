'********* Huge.Bas - shows how to exceed QB's 32K element number limit

'Copyright (c) 1988 Ethan Winer

DEFINT A-Z
GroupSize = 1000                                 'size of each element group
NumGroups = 100                                  'number of element groups
REDIM Array(1 TO GroupSize, 1 TO NumGroups)      'make a 2-dimensional array

Element& = 50000                                 'pick an element to assign
First = ((Element& - 1) MOD GroupSize) + 1       'calculate first subscript
PRINT "First ="; First
Second = (Element& - 1) \ GroupSize + 1          'same for the second
PRINT "Second ="; Second

Array(First, Second) = 123                       'assign the array element
CalcEl& = First + (Second - 1) * CLNG(GroupSize) 'show how to re-calc element
                                                 '(CLNG eliminates overflow)
PRINT "Array("; CalcEl&; ") ="; Array(First, Second)

