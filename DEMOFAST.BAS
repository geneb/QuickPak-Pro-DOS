'********** DEMOFAST.BAS - loads a file into a string array in one operation

'Copyright (c) 1989 Don Malin


DEFINT A-Z

DECLARE FUNCTION DOSError% ()
DECLARE FUNCTION ErrorMsg$ (ErrorNum)
DECLARE FUNCTION FileSize& (FileName$)
DECLARE FUNCTION FastLoadInt% (FileName$)
DECLARE FUNCTION FindLast% (BYVAL Address, Size)
DECLARE FUNCTION WaitKey% ()
DECLARE FUNCTION WhichError% ()

DECLARE SUB FastLoadStr (Text$())
DECLARE SUB FastSave (FileName$, Text$())

CLS
INPUT "Enter a file name to load: ", FileName$  'ask for a file name
Bytes& = FileSize&(FileName$)                   'get its size just for fun

StartTime! = TIMER                      'time how long the load takes
Lines = FastLoadInt%(FileName$)         'load the file, get number of lines

IF DOSError% THEN                       'if there was an error loading it,
   PRINT ErrorMsg$(WhichError%)         '  print an appropriate message
ELSE
   REDIM Text$(1 TO Lines)              'make an array to hold the text
   CALL FastLoadStr(Text$())            'move the text to the array
   EndTime! = TIMER - StartTime!        'now we know the elapsed time
   PRINT USING "#.##"; EndTime!;        'show how fast we loaded it
   PRINT " seconds to load"; Bytes&; "bytes - press a key to see it"
   Dummy = WaitKey%                     'pause for a key press

   FOR N = 1 TO Lines                   'print the text to prove it worked
       PRINT Text$(N)
   NEXT
END IF

PRINT
PRINT "Do you want to create a file and see how fast we can save it (Y/N)? ";
Answer = WaitKey%
IF Answer = ASC("Y") OR Answer = ASC("y") THEN

   PRINT
   LINE INPUT "Enter the name of the file to create: ", FileName$
   REDIM Text$(1 TO 1000)               'make an array of 1000 elements
   FOR X = 1 TO 500                     'show how to save only the first 500
       Text$(X) = "This is test line number" + STR$(X)
   NEXT

   StartTime! = TIMER                               'time how fast it happens
   CALL FastSave(FileName$, Text$())                'save the array
   IF DOSError% THEN PRINT ErrorMsg$(WhichError%)   'report any errors
   EndTime! = TIMER - StartTime!
   PRINT USING "#.##"; EndTime!;
   PRINT " seconds to save "; FileName$             'show the elapsed time
   KILL FileName$                                   'clean up after ourselves

END IF

