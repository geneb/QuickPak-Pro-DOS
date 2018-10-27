'********* COMPARE.BAS - tests the assembly language Compare routines


DEFINT A-Z
DECLARE FUNCTION Compare% (Seg1, Adr1, Seg2, Adr2, NumBytes)
DECLARE FUNCTION CompareT% (SEG Type1 AS ANY, SEG Type2 AS ANY, NumBytes)

TYPE Test
   S AS SINGLE
   T AS STRING * 20
END TYPE

CLS
X# = 1.23456789012345#
Y# = X# - .000000001#   'rem out the " - .000000001#" to make them the same
VarType = -4            'code for double precision (same code as in Sorts)

PRINT "Comparing the two double precision values ... ";
IF Compare%(VARSEG(X#), VARPTR(X#), VARSEG(Y#), VARPTR(Y#), VarType) THEN
   PRINT "They are the same!"
ELSE
   PRINT "Sorry, they're different"
END IF

DIM Type1 AS Test
DIM Type2 AS Test

Type1.S = 3.4
Type1.T = "Hi Mom"
Type2.S = 3.4           'change one of these to test
Type2.T = "Hi Mom"

PRINT
PRINT "Comparing the two TYPE variables ... ";
IF CompareT%(Type1, Type2, LEN(Type1)) THEN
   PRINT "They are the same!"
ELSE
   PRINT "Sorry, they're different"
END IF

