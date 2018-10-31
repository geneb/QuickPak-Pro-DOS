'********** DEMOXMS.BAS - demos the XMS stuff

'XMS software written by Dave Cleary
'Copyright (c) 1992 Crescent Software

'NOTE: This demonstration will not work if you are running under Windows
'unless you have told Windows in your DOS PIF file that it is to make
'XMS memory available.
'
'These routines and this demo were fashioned after the equivalent routines
'in QuickPak Professional for accessing EMS memory.


DEFINT A-Z

DECLARE FUNCTION XMSError% ()
DECLARE FUNCTION XMSLoaded% ()
DECLARE FUNCTION Peek1% (Segment, Address)

'The first pair of declares is for saving arrays, the second is for absolute
'memory locations.  Because we're using both methods in this demo, neither
'declare is used and the appropriate syntax is specified in the CALL.
'
'DECLARE SUB Array2Xms (SEG Element AS ANY, ElSize, NumEls, Handle)
'DECLARE SUB Array2Xms (BYVAL Segment, BYVAL Address, ElSize, NumEls, Handle)
'DECLARE SUB Xms2Array (SEG Element AS ANY, ElSize, NumEls, Handle)
'DECLARE SUB Xms2Array (BYVAL Segment, BYVAL Address, ElSize, NumEls, Handle)
'DECLARE SUB XmsGet1El(SEG Value AS ANY, ElSize, ElNum, Handle)
'DECLARE SUB XmsGet1El(BYVAL Segment, BYVAL Address, ElSize, ElNum, Handle)
'DECLARE SUB XmsSet1El(SEG Value AS ANY, ElSize, ElNum, Handle)
'DECLARE SUB XmsSet1El(BYVAL Segment, BYVAL Address, ElSize, ElNum, Handle)

DECLARE SUB XmsAllocMem (BYVAL NumK, Handle)
DECLARE SUB XmsRelMem (BYVAL Handle)
DECLARE SUB XmsSetError (BYVAL ErrNumber)
DECLARE SUB Poke1 (Segment, Address, Value)
DECLARE SUB XmsInfo (Info AS ANY)
DECLARE SUB UMBAllocMem (BYVAL NumBytes, UMBSeg)
DECLARE SUB UMBRelMem (BYVAL UMBSeg)

TYPE XMSInfoType
     XMSVersion AS INTEGER
     DriverVersion AS INTEGER
     NumHandles AS INTEGER
     FreeMem AS INTEGER
     Largest AS INTEGER
     HMAAvail AS INTEGER
     LargestUMB AS LONG
END TYPE

DIM XMS AS XMSInfoType

COLOR 2
CLS
IF XMSLoaded% THEN
   CALL XmsInfo(XMS)
   PRINT "The current XMS version on this system is"; XMS.XMSVersion% / 100
   PRINT "The internal version number is"; XMS.DriverVersion / 100
   PRINT "This XMS board has a total of"; XMS.FreeMem; "K bytes available";
   PRINT USING " (## MB)"; XMS.FreeMem * .001
   PRINT "Your largest free block is ";
   PRINT USING "##### K"; XMS.Largest
   PRINT "Your largest free UMB is ";
   PRINT USING "######## Bytes"; XMS.LargestUMB
   PRINT
ELSE
   PRINT "You clown, you don't even have XMS memory!"
   END
END IF
PRINT "Press any key to continue ..."
CALL WaitKey

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


'----- Save the array to XMS memory
PRINT "Saving the array to XMS memory ...."
CALL Array2Xms(SEG Array#(1), ElSize, NumEls, XmsHandle)

IF XMSError% THEN
   PRINT
   PRINT "Error number"; XMSError%; "occurred while saving the array"
   END
ELSE
   PRINT "This data is saved under handle number "; HEX$(XmsHandle)
   PRINT
END IF


'----- Get it back again
REDIM Array#(1 TO NumEls)
PRINT "Retrieving the array from XMS memory"
CALL Xms2Array(SEG Array#(1), ElSize, NumEls, XmsHandle)
IF XMSError% THEN
   PRINT "Error number"; XMSError%; "occurred"
   END
END IF
CALL XmsRelMem(XmsHandle)


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
PRINT "Allocating 32 KBytes ... "
CALL XmsAllocMem(32, XmsHandle)         'request two 16K pages
IF XMSError% = 160 THEN
   PRINT "Insufficient XMS memory."
   END
END IF

PRINT "Assigning 100 elements in a "; CHR$(34); "byte"; CHR$(34); " array ..."
FOR X = 27136 TO 27136 + 99             'assign 100 elements near end of array
    Value = X MOD 256                   'byte values range only from 0 to 255
    CALL XmsSet1El(SEG Value, 1, X, XmsHandle)
NEXT

PRINT "Checking values for accuracy ..."
PRINT
FOR X = 27136 TO 27136 + 99             'now read them back
    CALL XmsGet1El(SEG Value, 1, X, XmsHandle)
    PRINT Value;
NEXT

CALL XmsRelMem(XmsHandle)       'close the handle and release the memory
PRINT
PRINT


'----- Copy the current text screen into XMS and back again
PRINT "Now we'll save this text screen, and then bring it back again - ";
COLOR 2 + 16
PRINT "press a key";
COLOR 7

IF Peek1%(0, &H463) = &HB4 THEN         'monochrome
   VideoSeg = &HB000
ELSE                                    'color
   VideoSeg = &HB800
END IF

CALL Array2Xms(BYVAL VideoSeg, BYVAL 0, 4000, 1, XmsHandle)
CALL WaitKey

CLS
PRINT "Press a key to bring the screen back again";
CALL WaitKey
CALL Xms2Array(BYVAL VideoSeg, BYVAL 0, 4000, 1, XmsHandle)
CALL XmsRelMem(XmsHandle)       'close the handle and release the memory
CALL WaitKey


'----- Store four separate text screens using an "element" size of 4000
CLS
PRINT "When you press a key, we'll create four text screens and save each one."
CALL WaitKey
LOCATE 1

IF XMS.LargestUMB > 16000 THEN          'Use UMBs if available
   CALL UMBAllocMem(16000, UMBSeg)      'Get our memory
   IF XMSError% THEN
      PRINT "Error allocating UMB."
      END
   END IF

   FOR X = 1 TO 4                       'fill screen with digits
       CALL QPrint0(STRING$(2000, LTRIM$(STR$(X))), 7)
       VideoOfs = (X - 1) * 4000
       CALL BCopy(VideoSeg, 0, UMBSeg, VideoOfs, 4000, 0) 'save each screen
   NEXT

   CLS
   PRINT "Now press a key to retrieve each screen in succession."
   FOR X = 1 TO 4
       CALL WaitKey
       VideoOfs = (X - 1) * 4000
       CALL BCopy(UMBSeg, VideoOfs, VideoSeg, 0, 4000, 0)  'restore screens
   NEXT

   CALL UMBRelMem(UMBSeg)               'Must call as UMB's aren't released
					'automatically

ELSE                                    'Insufficient UMBs, use regular XMS
   CALL XmsAllocMem(16, XmsHandle)      'request 1-16K page (holds 4 screens)
   FOR X = 1 TO 4
       CALL QPrint0(STRING$(2000, LTRIM$(STR$(X))), 7) 'fill each screen
       CALL XmsSet1El(BYVAL VideoSeg, BYVAL 0, 4000, X, XmsHandle) 'save it
   NEXT

   CLS
   PRINT "Now press a key to retrieve each screen in succession."
   FOR X = 1 TO 4
       CALL WaitKey
       CALL XmsGet1El(BYVAL VideoSeg, BYVAL 0, 4000, X, XmsHandle)
   NEXT
   CALL XmsRelMem(XmsHandle)
END IF

