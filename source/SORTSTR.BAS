'********** SortStr.Bas - loads a text file and sorts the lines

'Copyright (c) 1987 Ethan Winer


DEFINT A-Z
DECLARE SUB SortStr (BYVAL Address, Size, Direction)
DECLARE SUB SortStr2 (BYVAL Address, Size, Direction)
DECLARE FUNCTION LineCount% (FileName$, Buffer$)
DECLARE FUNCTION FileSize& (FileName$)

CLS
LOCATE , , 1
PRINT "File to load and sort: ";                'ask for a file to sort
LINE INPUT FileName$
IF FileSize&(FileName$) > (FRE("") - 2000) THEN
   PRINT "Not enough memory to load this file"
   END
END IF

CLS
PRINT "Ascending or Descending? (A/D) ";

DO
   X$ = UCASE$(INKEY$)
LOOP UNTIL X$ = "A" OR X$ = "D"
IF X$ = "A" THEN
   Dir = 0
ELSE
   Dir = 1
END IF

CLS
PRINT "Case Sensitive or Insensitive? (S/I) ";

DO
   X$ = UCASE$(INKEY$)
LOOP UNTIL X$ = "S" OR X$ = "I"
IF X$ = "S" THEN
   C = 1
ELSE
   C = 0
END IF

Lines = LineCount%(FileName$, SPACE$(4096))     'count the number of lines
DIM A$(Lines)                                   'make an array to hold it

OPEN FileName$ FOR INPUT AS #1                  'read the file into an array
Lines = 0
WHILE NOT EOF(1)
  Lines = Lines + 1
  LINE INPUT #1, A$(Lines)
WEND
CLOSE

Start = 1                       'specify sorting the whole array
Size = Lines
PLAY "L32O3AF"

CLS
PRINT "Press any key to begin sorting ";

WHILE INKEY$ = "": WEND                 'pause for keypress
X! = TIMER                              'so we can time the sort

IF C THEN
   SortStr VARPTR(A$(Start)), Size, Dir         'sort ascending
ELSE
   SortStr2 VARPTR(A$(Start)), Size, Dir        'sort descending
END IF

CLS
PRINT USING "Time: ##.## Seconds"; TIMER - X!;
PLAY "AF"

PRINT " - press any key to display sorted array ";
WHILE INKEY$ = "": WEND

LOCATE 25, 1, 0
PRINT "Press any key to pause";
LOCATE 3, 1

FOR X = 1 TO Size
    PRINT LEFT$(A$(X), 79)          'in case the lines are very long
    IF INKEY$ <> "" THEN
       WHILE INKEY$ = "": WEND      'pause on keypress
    END IF
NEXT

