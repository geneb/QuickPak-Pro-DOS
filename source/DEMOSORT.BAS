'********** DEMOSORT.BAS - demonstrates FILESORT.BAS

'Copyright (c) 1989-1990 Crescent Software
'written by Paul Passarelli


'IMPORTANT NOTE: The FileSort program creates a "huge" array for use as a
'work space.  Therefore, you must compile it using the /ah BC.EXE option.


DEFINT A-Z
DECLARE SUB FileSort (DataFile$, IndexFile$, First&, Last&, Table(), RecLength)
DECLARE SUB Pause (Ticks)

DECLARE FUNCTION DOSError% ()
DECLARE FUNCTION ErrorMsg$ (ErrNum)
DECLARE FUNCTION Exist% (FileName$)
DECLARE FUNCTION WhichError% ()

TYPE Test               'this is a sample record layout for this test
   I AS INTEGER
   L AS LONG
   S AS SINGLE
   D AS DOUBLE
   X AS STRING * 20
END TYPE

CLEAR , , 2000          'reserve sufficient stack space for very large files
DIM Info AS Test        'make a TYPE variable to describe the record layout
NumEls& = 450                   'the number of records to create
DatFile$ = "FILESORT.DAT"       'the primary test file name to create
NdxFile$ = "FILESORT.NDX"       'the index file name to generate

CLS
IF Exist%(DatFile$) THEN KILL DatFile$          'kill any old data file
PRINT "  Creating"; NumEls&; "records . . ."     'advise what's going on

OPEN DatFile$ FOR RANDOM AS #1 LEN = LEN(Info)  'create the sample data file
FOR J& = 1 TO NumEls&                   'create some random data to sort
    Info.I = RND(1) * 2 + 1             'limit the ranges to 1 - 3
    Info.L = RND(1) * 2 + 1
    Info.S = RND(1) * 2 + 1
    Info.D = RND(1) * 3200000 - RND(1) * 3200000        'use bigger range here
    Info.X = CHR$(RND(1) * 25 + 65) + STRING$(19, ".")  'make a random string
    PUT #1, , Info                                      'write this record
NEXT
CLOSE

NumberOfKeys = 3                              'the total number of sort keys
DIM Table(1 TO NumberOfKeys, 1 TO 3)          'dimension the key table array
'
'Table is a 2 dimensional table of sorting information set up as follows:
'
'   Element 1,1 is the offset into the element for the primary key.
'   Element 1,2 is the size/code for the type of data being considered.
'   Element 1,3 is 0 or 1 for ascending or descending respectively.
'
'   Element 2,1 is the offset into the element for the secondary key, and
'   so forth, through the last sort key.
'
'   The size of the table array - that is, UBOUND(Table, 1) - tells KeySort
'   how many keys to sort, so always dimension it only to the size necessary.
'
FOR X = 1 TO NumberOfKeys 'read the offsets, type codes, and sort directions
    FOR Y = 1 TO 3
    READ Table(X, Y)
    NEXT
NEXT

DATA 18, 20, 0  : 'The primary sort is on the fixed-length string, which
                  '  starts 18 bytes into the structure.  The string length
                  '  is 20, and we want to do an ascending sort
DATA 0, -1, 1   : 'the int is the second key, length code is -1, descending
DATA 10, -4, 0  : 'the double is the third key, length code is -4, ascending

LOCATE 1, 1: PRINT "   Sor";
CALL FileSort(DatFile$, NdxFile$, 0, Last&, Table(), LEN(Info))     'do it to it
IF DOSError% THEN                                               'see if error
   PRINT ErrorMsg$(WhichError%); " error occurred - ending"
   END
END IF

'----- read the index file and display the records in sorted order
OPEN DatFile$ FOR RANDOM AS #2 LEN = LEN(Info)
OPEN NdxFile$ FOR RANDOM AS #1 LEN = 4
CLS
PRINT " Item#  Record #  "; " String (ascending)"; TAB(42); "Int (descending)"; TAB(61); "Double (ascending)";
PRINT STRING$(79, "=")
LOCATE 24, 1: PRINT STRING$(79, "=");
LOCATE 25, 1: PRINT "Press any key to pause";

VIEW PRINT 3 TO 23                      'limit printing to lines 3 through 23
LOCATE 3, 1
ChgColor = 10

FOR X& = 1 TO Last&
    GET #1, X&, RecNo&                    'get the next record number to read
    GET #2, RecNo&, Info                'get the appropriate data record
    IF Info.X <> Last$ THEN PRINT       'add delimiting space between groups
    IF Info.I <> LastI THEN             'alternate colors each new Int group
       IF ChgColor = 10 THEN
          ChgColor = 2
       ELSE
          ChgColor = 10
       END IF
       COLOR ChgColor
    END IF

    PRINT X&; TAB(8); RecNo&; TAB(20); Info.X; TAB(50); Info.I; SPC(7);
    PRINT USING "##########.###"; Info.D

    IF LEN(INKEY$) THEN         'pause on any key press
       WHILE INKEY$ = "": WEND  'resume on the next press
    END IF

    Last$ = Info.X              'remember the last values so we know when to
    LastI = Info.I              'break a new string group, and change colors
                                '  at the start of each new integer sub-group
    Pause 1                     'slight delay to slow down the scrolling
NEXT
CLOSE

KILL NdxFile$
KILL DatFile$

