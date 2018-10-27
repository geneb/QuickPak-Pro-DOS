'********** RWTest.Bas - determines if a drive is ready for reading/writing

'Copyright (c) 1987 by Ethan Winer


'ReadTest does NOT check to see if a valid drive has been specified.
'It only tests to see that a disk is in the drive, and the door is closed.
'If you also need to determine whether the drive letter is valid, GetLast
'will do this nicely for you.

'WritTest will determine if a drive is ready to be written to, however
'it does NOT detect if the disk is merely full, which it reports as being
'okay.  If you need to insure against insufficient disk space, use the
'DiskRoom function first.  Otherwise, any errors caused by the drive door
'being open, no disk, a write protect tab, etc. can be trapped without
'requiring On Error and the /E compile option.  Notice that WritTest creates
'a temporary file called "LIKE-WOW.MAN" on the disk being tested.  In the
'unlikely event that a file with that name is already present, it will be
'overwritten in the process.


DECLARE FUNCTION ReadTest% (Drive$)
DECLARE FUNCTION WriteTest% (Drive$)
DECLARE FUNCTION LastDrive% ()

CLS
LOCATE , , 1
PRINT "Which drive (Enter for the default)? ";
Drive$ = UCASE$(INPUT$(1))
PRINT : PRINT

IF ASC(Drive$) > LastDrive% THEN
   PRINT "Invalid drive!"
   END
END IF

IF ASC(Drive$) < 65 THEN Drive$ = ""    'use default if they pressed Enter

RT = ReadTest%(Drive$)
WT = WriteTest%(Drive$)

IF RT THEN PRINT "Ready to read"
IF WT THEN PRINT "Ready to write"
IF RT AND NOT WT THEN PRINT "Write protected"
IF NOT RT AND NOT WT THEN PRINT "Drive not ready!"

