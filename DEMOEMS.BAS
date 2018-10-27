'********** DEMOEMS.BAS - demos the EMS stuff

'Copyright (c) 1988-1991 Crescent Software


'WARNING: If you are using BASIC 7 PDS you must start QBX with the /es switch.


DEFINT A-Z

DECLARE FUNCTION EmsError% ()
DECLARE FUNCTION EmsLoaded% ()
DECLARE FUNCTION EmsVersion% ()
DECLARE FUNCTION EmsPageCount% ()
DECLARE FUNCTION EmsPagesFree% ()
DECLARE FUNCTION EmsGetPFSeg% ()
DECLARE FUNCTION EmsNumPages% (Handle)
DECLARE FUNCTION Peek1% (Segment, Address)


'The first pair of declares is for saving arrays, the second is for absolute
'memory locations.  Because we're using both methods in this demo, neither
'declare is used and the appropriate syntax is specified in the CALL.
'
'DECLARE SUB Array2Ems (SEG Element AS ANY, ElSize, NumEls, Handle)
'DECLARE SUB Array2Ems (BYVAL Segment, BYVAL Address, ElSize, NumEls, Handle)
'DECLARE SUB Ems2Array (SEG Element AS ANY, ElSize, NumEls, Handle)
'DECLARE SUB Ems2Array (BYVAL Segment, BYVAL Address, ElSize, NumEls, Handle)
'DECLARE SUB EmsGet1El(SEG Value AS ANY, ElSize, ElNum, Handle)
'DECLARE SUB EmsGet1El(BYVAL Segment, BYVAL Address, ElSize, ElNum, Handle)
'DECLARE SUB EmsSet1El(SEG Value AS ANY, ElSize, ElNum, Handle)
'DECLARE SUB EmsSet1El(BYVAL Segment, BYVAL Address, ElSize, ElNum, Handle)

DECLARE SUB EmsAllocMem (NumPages, Handle)
DECLARE SUB EmsRelMem (Handle)
DECLARE SUB EmsSetError (ErrNumber)
DECLARE SUB EmsSetPage (Page, Handle)
DECLARE SUB Poke1 (Segment, Address, Value)


COLOR 2
CLS
IF EmsLoaded% THEN
   PRINT "The current EMS version on this system is"; EmsVersion% / 100
   PRINT "This EMS board has a total of"; EmsPageCount%; "16K pages available ";
   PRINT "("; EmsPageCount% / 64; "MB )"
   PRINT "You presently have"; EmsPagesFree%; "pages free ";
   PRINT "("; EmsPagesFree% * 16; "KB )"
   PRINT
ELSE
   PRINT "You clown, you don't even have an EMS board!"
   END
END IF


'----- Make an array and fill it with sequential numbers
PRINT "Creating a sample data array .";
NumEls = 5000
ElSize = 8
REDIM Array#(1 TO NumEls)

FOR N = 1 TO NumEls
    IF N MOD 1000 = 0 THEN PRINT ".";
    Array#(N) = N
NEXT
PRINT


'----- Save the array to EMS memory
PRINT "Saving the array to EMS memory ...."
CALL Array2Ems(SEG Array#(1), ElSize, NumEls, EmsHandle)

IF EmsError% THEN
   PRINT
   PRINT "Error number"; EmsError%; "occurred while saving the array"
   END
ELSE
   PRINT "This data is saved under handle number "; HEX$(EmsHandle);
   PRINT ", and occupies"; EmsNumPages%(EmsHandle); "16K pages"
   PRINT
END IF


'----- Get it back again
REDIM Array#(1 TO NumEls)
PRINT "Retrieving the array from EMS memory"
CALL Ems2Array(SEG Array#(1), ElSize, NumEls, EmsHandle)
IF EmsError% THEN
   PRINT "Error number"; EmsError%; "occurred"
   END
END IF
CALL EmsRelMem(EmsHandle)


'----- Print the array contents to show we got it back okay
PRINT "Checking the array for accuracy ..."
PRINT
FOR N = 1 TO NumEls
    IF Array#(N) <> N THEN
       BEEP
       PRINT "Error in element"; N
       WHILE INKEY$ = "": WEND
    END IF
    IF N MOD 1000 = 0 THEN PRINT Array#(N),
NEXT
PRINT


'----- Allocate two 16K pages, to create a 32,768 element "byte" array
PRINT "Allocating 2 EMS pages ... "
EmsAllocMem 2, EmsHandle                'request two 16K pages
IF EmsError% = 133 OR EmsError% >= 135 THEN
   PRINT "Insufficient EMS memory."
   END
END IF

PRINT "Assigning 100 elements in a "; CHR$(34); "byte"; CHR$(34); " array ..."
FOR X = 27136 TO 27136 + 99             'assign 100 elements near end of array
    Value = X MOD 256                   'byte values range only from 0 to 255
    CALL EmsSet1El(SEG Value, 1, X, EmsHandle)
NEXT

PRINT "Checking values for accuracy ..."
PRINT
FOR X = 27136 TO 27136 + 99             'now read them back
    CALL EmsGet1El(SEG Value, 1, X, EmsHandle)
    PRINT Value;
NEXT

CALL EmsRelMem(EmsHandle)       'close the handle and release the memory
PRINT
PRINT


'----- Copy the current text screen into EMS and back again
PRINT "Now we'll save this text screen, and then bring it back again - ";
COLOR 2 + 16
PRINT "press a key";
COLOR 7
IF Peek1%(0, &H463) = &HB4 THEN         'monochrome
   VideoSeg = &HB000
ELSE                                    'color
   VideoSeg = &HB800
END IF

CALL Array2Ems(BYVAL VideoSeg, BYVAL 0, 4000, 1, EmsHandle)
CALL WaitKey

CLS
PRINT "Press a key to bring the screen back again";
CALL WaitKey
CALL Ems2Array(BYVAL VideoSeg, BYVAL 0, 4000, 1, EmsHandle)
CALL EmsRelMem(EmsHandle)       'close the handle and release the memory
CALL WaitKey


'----- Store four separate text screens using an "element" size of 4000
CLS
PRINT "When you press a key, we'll create four text screens and save each one."
CALL WaitKey
LOCATE 1
CALL EmsAllocMem(1, EmsHandle)  'request 1 16K page (holds 4 screens)
FOR X = 1 TO 4
    CALL QPrint0(STRING$(2000, LTRIM$(STR$(X))), 7) 'fill screen with digits
    CALL EmsSet1El(BYVAL VideoSeg, BYVAL 0, 4000, X, EmsHandle) 'save it
NEXT

CLS
PRINT "Now press a key to retrieve each screen in succession."
FOR X = 1 TO 4
    CALL WaitKey
    CALL EmsGet1El(BYVAL VideoSeg, BYVAL 0, 4000, X, EmsHandle)
NEXT
CALL EmsRelMem(EmsHandle)

