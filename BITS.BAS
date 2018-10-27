'********** BITS.BAS - allows creating and manipulating "bit" arrays

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z

DECLARE SUB DimBits (Array$, ArraySize)         'dims a bit array
DECLARE SUB SetBit (Array$, BitNumber, Bit)     'assigns to the bit array
DECLARE FUNCTION GetBit% (Array$, BitNumber)    'returns elements from array

CLS
Element = 195                   'the element number to test
NumEls = 5000                   'use 5000 array elements
CALL DimBits(Array$, NumEls)    'dim the array

FOR X = 0 TO NumEls             'show that it worked
  IF GetBit%(Array$, X) THEN
    PRINT "Element"; X; "is set" 'should NOT be set right after DIMming
  END IF
NEXT

SetBit Array$, Element, 1       'assign element = On
PRINT "Setting bit number"; Element; "to On"

FOR X = 0 TO NumEls             'examine all of the elements to prove it works
  IF GetBit%(Array$, X) THEN    'should show only element number Element
    PRINT "Element"; X; "is set"
  END IF
NEXT

SUB DimBits (Array$, ArraySize)
  Array$ = STRING$(ArraySize \ 8 + 1, 0)        'each character holds 8 bits
END SUB

