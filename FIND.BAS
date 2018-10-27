'********** Find.Bas - demonstrates searching an entire array for a sub-string

'Copyright (c) 1988 Ethan Winer


'There are four versions of Find to locate a string or sub-string in an array.
'This demo shows only the case-insensitive versions.
'
'   Find searches forward and is case-sensitive
'   Find2 also searches forward, but ignores capitalization
'   FindB searches backwards and honors capitalization
'   FindB2 searches backwards and ignores capitalization
'
'Notes:
'
'   Because FindB and FindB2 know which element they are starting with, they
'   are able to return the element number at which the match was found.  But
'   Find and Find2 can't know how large the array is, so thet are set up
'   to instead return the number of elements that were searched.  All four
'   routines use -1 to indicate that a match was not found, however Find and
'   Find2 will report 0 if the match was made on the element they started
'   searching with.  If you start on, say, element 10 and Find (or Find2)
'   found a match at element 12, they would return 2 meaning two elements
'   BEYOND the current one were examined.  The examples below show all of
'   this in context.


DEFINT A-Z
DECLARE SUB Find2 (BYVAL Address, Element, Search$)
DECLARE SUB FindB2 (BYVAL Address, Element, Search$)

Size = 10
DIM Array$(Size)

FOR X = 0 TO Size
    READ Array$(X)
NEXT

DATA "Smith, Harold"
DATA "Rogers, Maude"
DATA "Smith, Arthur"
DATA "Jacki Pagliari"
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

'*************** Search forward

   Start = 0                    'start searching at the first element
   Elements = Size              'search the entire array

Forward:
   Find2 VARPTR(Array$(Start)), Elements, Search$
						  
   'first see if it was there - Find returns -1 if it isn't found
   IF Elements = -1 THEN
      PRINT "Not Found"
      END
   END IF

   Start = Start + Elements     'calculate the element number it was found at
				'Elements returns with how far it searched,
				'  not an actual element number

   PRINT Start; TAB(7); Array$(Start)   'print the matching element
   IF Start = Size THEN END            'it was found at the last element -
					'  don't ask if they want to continue
   PRINT
   PRINT "Continue searching? (Y/N) ";

   DO
      X$ = UCASE$(INKEY$)
   LOOP UNTIL X$ = "Y" OR X$ = "N"

   PRINT X$
   PRINT
   IF X$ <> "Y" THEN END

   Elements = Size - Start - 1  'consider only the remaining part of the array
   Start = Start + 1            'continue from the next element
   IF Elements <= Size GOTO Forward     'continue search only if there's more

ELSE

   '************** Search backwards

   Elements = Size              'search entire array starting at the beginning

Backward:
   FindB2 VARPTR(Array$(Elements)), Elements, Search$

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

