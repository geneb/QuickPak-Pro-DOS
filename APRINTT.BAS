'********** APRINTT.BAS - APrint demo for fixed-length strings

'Copyright (c) 1988 Ethan Winer


'IMPORTANT NOTE:  To run this program you MUST start QB like this:
'
'    QB APrintT /AH /L Pro   - the /AH is needed because of the Huge array
'
'NOTE: This demo is implemented to prove that APrintT correctly handles
'      elements that cross a segment boundary.


DEFINT A-Z

'Defining a fixed length string as a TYPE greatly simplifies the call to
'APrintT below.  The alternative method using a fixed-length string array
'is shown in REMarks for comparison.

TYPE FLen
   S AS STRING * 30
END TYPE

DECLARE SUB APrintT (SEG ArrayElement AS FLen, ElSize, NumEls, MidStart, NumChars, Colr, Page)
'DECLARE SUB APrintT (BYVAL Segment, BYVAL Address, ElSize, NumEls, MidStart, NumChars, Colr, Page)

DEF FnSigned& (X)                       'for testing only
  IF X < 0 THEN
     FnSigned& = X + 65536
  ELSE
     FnSigned& = X
  END IF
END DEF

REDIM Array(3100) AS FLen
'REDIM Array(3100) AS STRING * 30

CLS
OPEN "KeySort.Bas" FOR INPUT AS #1
FOR X = 2100 TO 2200
  LINE INPUT #1, Array(X).S
 'LINE INPUT #1, Array$(X)
  IF X >= 2175 AND X < 2195 THEN
    PRINT FnSigned&(VARPTR(Array(X).S)); TAB(10); Array(X).S
   'PRINT FnSigned&(VARPTR(Array$(X))); TAB(10); Array$(X)
  END IF
NEXT

LOCATE 1, 45
CALL APrintT(Array(2175), 30, 20, 1, 30, 7, -1)
'CALL APrintT (VARSEG(Array$(2175)), VARPTR(Array$(2175)), 30, 20, 1, 30, 7, -1)

