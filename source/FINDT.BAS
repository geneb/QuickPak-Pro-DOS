'********** FindT.Bas - demos searching a fixed-length array for a sub-string

'Copyright (c) 1988 Ethan Winer


'There are four versions of Find to locate a string or sub-string in an array.
'This demo shows only the case-insensitive versions.
'
'  FindT searches forward and is case-sensitive
'  FindT2 also searches forward, but ignores capitalization
'  FindTB searches backwards and honors capitalization
'  FindTB2 searches backwards and ignores capitalization
'
'Notes:
'
'  Because FindTB and FindTB2 know which element they are starting with, they
'  are able to return the element number at which the match was found.  But
'  FindT and FindT2 can't not know how large the array is, so thet are set up
'  to instead return the number of elements that were searched.  All four
'  routines use -1 to indicate that a match was not found, however Find and
'  FindT2 will report 0 if the match was made on the element they started
'  searching with.  If you start on, say, element 10 and FindT (or FindT2)
'  found a match at element 12, they would return 2 meaning two elements
'  BEYOND the current one were examined.  The examples below show all of
'  this in context.


DEFINT A-Z
DECLARE SUB FindT2 (BYVAL Segment, BYVAL Address, ElSize, Element, Search$)
DECLARE SUB FindTB2 (BYVAL Segment, BYVAL Address, ElSize, Element, Search$)

Size = 5000
ElSize = 20
REDIM Array(Size) AS STRING * 20

FOR X = 0 TO 10
    READ Array$(X)
NEXT
Array(Size) = "Find me hiding here"

DATA "Smith, Harold"
DATA "Rogers, Maude"
DATA "Smith, Arthur"
DATA "Sureta Escobar"
DATA "Rogers, Carl J."
DATA "Rubin, Fenster"
DATA "Smythson, Wendy"
DATA "Plant, Gail H."
DATA "Smith Barney & Co."
DATA "Ericson, Sven"
DATA "Babbage, Charles"

CLS
LINE INPUT "Enter a string to search for (hint - try sm?th): "; Search$
PRINT "Search forward or backward (F/B)? ";

DO
    FDir$ = UCASE$(INKEY$)
LOOP UNTIL FDir$ = "F" OR FDir$ = "B"

PRINT FDir$
PRINT

IF FDir$ = "F" THEN

'----- Search forward

   Start = 0                    'start searching at the first element
   Elements = Size              'search the entire array

Forward:
   FindT2 VARSEG(Array$(Start)), VARPTR(Array$(Start)), ElSize, Elements, Search$
						  
   'First see if it was there.  FindT2 returns -1 if it isn't found, but also
   'check to be sure it didn't happen to match some garbage in memory that
   'looked like Search$.
   IF Elements = -1 OR Start + Elements > Size THEN
      PRINT "Not Found"
      END
   END IF

   Start = Start + Elements     'calculate the element number it was found at
				'Elements returns with how far it searched,
				'  not an actual element number

   PRINT Start; TAB(7); Array$(Start)   'print the matching element
   IF Start = Size THEN END             'it was found at the last element -
					'  don't ask if they want to continue
   PRINT
   PRINT "Continue searching? (Y/N) ";

   DO
      X$ = UCASE$(INKEY$)
   LOOP UNTIL X$ = "Y" OR X$ = "N"

   PRINT X$
   PRINT
   IF X$ <> "Y" THEN END

   Elements = Size - Start      'consider only the remaining part of the array
   Start = Start + 1            'continue from the next element
   IF Elements <= Size GOTO Forward     'continue search only if there's more

ELSE

'----- Search backwards

   Elements = Size              'search entire array starting at the beginning

Backward:
   FindTB2 VARSEG(Array$(Elements)), VARPTR(Array$(Elements)), ElSize, Elements, Search$

   IF Elements = -1 THEN        'Find returns -1 if it isn't found
      PRINT "Not Found"
      END
   END IF

   PRINT Elements; TAB(7); Array$(Elements)
   IF Elements = 0 THEN END     'it was at the first element - don't ask
				'  if they want to continue

   PRINT "Continue searching? (Y/N) ";

   DO
      X$ = UCASE$(INKEY$)
   LOOP UNTIL X$ = "Y" OR X$ = "N"

   PRINT X$
   PRINT
   IF X$ <> "Y" THEN END

   Elements = Elements - 1      'continue with the previous element
   GOTO Backward

END IF

