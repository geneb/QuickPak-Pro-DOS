'********** Fill.Bas - demonstrates quickly filling numeric arrays

'Copyright (c) 1988 Ethan Winer


DECLARE SUB Fill2 (SEG ArrayEl%, Value%, Size%)
DECLARE SUB Fill4 (SEG ArrayEl!, Value!, Size%)
DECLARE SUB Fill8 (SEG ArrayEl#, Value#, Size%)
DECLARE SUB AddInt (SEG ArrayEl%, Value%, Size%)

REDIM Array%(5000), Array!(5000), Array#(5000)

Value% = 14
Value! = 14.987
Value# = 14.98723568#
Size% = 5000                            'number of bytes to fill

Fill2 Array%(1), Value%, Size%          'fill each array
Fill4 Array!(1), Value!, Size%
Fill8 Array#(1), Value#, Size%
   
CLS                                     'show that we got all of 'em
PRINT "             Element:        #1            #2500         #5000"
PRINT TAB(30); STRING$(40, 95)
PRINT
PRINT "Filled Integer Array:", Array%(1), Array%(2500), Array%(5000)

PRINT
PRINT "Filled Single Precision:", Array!(1), Array!(2500), Array!(5000)

PRINT
PRINT "Filled Double Precision:", Array#(1), Array#(2500), Array#(5000)

PRINT
PRINT
PRINT "Here are elements 97 through 101:"
PRINT

Size% = 2
Value% = -87                            'now let's do just a portion
Value! = -87.904
Value# = -.0007654#

Fill2 Array%(99), Value%, Size%
Fill4 Array!(99), Value!, Size%
Fill8 Array#(99), Value#, Size%

PRINT Array%(97), Array%(98), Array%(99), Array%(100), Array%(101)
PRINT Array!(97), Array!(98), Array!(99), Array!(100), Array!(101)
PRINT Array#(97), Array#(98), Array#(99), Array#(100), Array#(101)

Value% = 2
Size% = 5000

PRINT
PRINT
PRINT "Here's the integer array after adding"; Value%; CHR$(29); ":"
PRINT
CALL AddInt(Array%(1), Value%, Size%)
FOR X% = 97 TO 101
    PRINT Array%(X%),
NEXT
PRINT
PRINT "(You can easily subtract from the array by using a negative number.)"

