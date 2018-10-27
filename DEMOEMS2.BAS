'******** DEMOEMS2.BAS -- demos an EMS-related Basic Function and some
'                         handy Basic Subroutines for manipulating
'                         two-dimensional arrays stored in EMS memory.
'
'--- Developed by Tom Renckly

DEFINT A-Z

' This demo illustrates several basic subroutines and functions that are
' designed to make it easy to manipulate two-dimensional data arrays stored
' in EMS memory.  These routines only work with numeric arrays; string arrays
' are a different story altogether!  Also, these routines are designed to
' work with either OPTION BASE 0 or 1 arrays.
'
' If you use single or double precision or long integer arrays, you must
' change the Array%() designation to Array!(), Array#(), or Array&() (as
' appropriate) everywhere throughout the four Basic subroutines marked by
' asterisks in the list below.
'
' The heart of this set of EMS array routines is the Basic function named
' Element&.  When passed the row and column array indexes for the array
' element desired, Element& calculates the correct "offset" into the EMS
' array.  This function is necessary since the QuickPak EMS routines store
' multi-dimensional arrays in EMS memory in column-major order rather than
' the row-major order you may be used to with multidimensional arrays stored
' in RAM.


' Basic Function

DECLARE FUNCTION Element& (Row, Column) ' Calculates offset into EMS array

' Basic Subroutines

DECLARE SUB PutArray2Ems ()             ' Place a 2-D array into EMS
DECLARE SUB PutEms2Array ()             ' Retrieve a 2-D array from EMS
DECLARE SUB GetEl (Row, Column, ArrayElement%)  ' Get 1 element from EMS array
DECLARE SUB GetRow (Row)                ' Get a whole row of elements (**)
DECLARE SUB GetCol (Column)             ' Get a column of elements (**)
DECLARE SUB SetEl (Row, Column, NewValue%) ' Put data into EMS array element
DECLARE SUB Swap2Rows (Row1, Row2)      ' Swap 2 rows in an EMS array (**)
DECLARE SUB Swap2Cols (Col1, Col2)      ' Swap 2 columns in an EMS array (**)

' Assembler Subroutines

DECLARE SUB Array2Ems (SEG ArrayElement AS ANY, ElSize%, NumEls&, Handle%)
DECLARE SUB ClearBuf ()
DECLARE SUB ClearScr0 (ULRow%, ULCol%, LRRow%, LRCol%, Colr%)
DECLARE SUB EmsGet1El (SEG Value AS ANY, ElSize, ElNum&, Handle)
DECLARE SUB EmsSet1El (SEG Value AS ANY, ElSize, ElNum&, Handle)
DECLARE SUB EmsRelMem (Handle%)
DECLARE SUB InitInt (SEG Address%, StartValue%, NumEls&)

' Assembler Functions

DECLARE FUNCTION EmsLoaded% ()
DECLARE FUNCTION EmsPagesFree% ()
DECLARE FUNCTION QInstr% (Start%, Source$, Search$)
DECLARE FUNCTION QPLeft$ (work$, NumChars%)
DECLARE FUNCTION QPRight$ (work$, NumChars%)
DECLARE FUNCTION QPStrI$ (IntVar%)
DECLARE FUNCTION QPValI% (work$)

' Establish a set of variables that can be shared by all modules

DIM SHARED ElSize%, NumEls&, NumRows, NumCols, RowLBound, ColLBound
DIM SHARED EmsArrayHandle%

' First, dimension an array and share it among all modules

REDIM SHARED Array%(5, 10)     '  Set these dimensions as desired.

' Next, find total number of elements in Array%()

NumEls& = CLNG(UBOUND(Array%, 1) + 1) * CLNG(UBOUND(Array%, 2) + 1)
NumRows = UBOUND(Array%, 1)
NumCols = UBOUND(Array%, 2)
RowLBound = LBOUND(Array%, 1)
ColLBound = LBOUND(Array%, 2)
ElSize% = 2  ' use 2 since we're dealing with an integer array.
             ' change this to 4 or 8 if your array contains single precision,
             ' double precision, or long integers.

REDIM SHARED ReturnRow%(NumCols), ReturnCol%(NumRows) ' used in GetRow/GetCol

' Check to see if sufficient EMS memory is available to work with

IF NOT EmsLoaded% THEN
   PRINT : PRINT "   We can't go any farther - You don't have EMS in this PC."
   END
END IF
IF CLNG(EmsPagesFree%) * 16384 < CLNG(NumEls%) * CLNG(ElSize%) THEN
   PRINT : PRINT "   We can't go any farther - You don't have enough EMS."
   END
END IF

' Next, fill the array with sequential numbers - for demo purposes only.

CALL InitInt(SEG Array%(RowLBound, ColLBound), 1, NumEls&)

' ********** Display array on screen to show what it looks like, **********

CLS
PRINT "  This is what our demonstration array looks like.  It contains 6 rows"
PRINT "  (0 through 5) and eleven columns (0 through 10).  The numbers you see"
PRINT "  are the actual values stored in each array element."

GOSUB PrintArray

PRINT
PRINT "  For instance, Array%(0,0) holds value"; Array%(0, 0); ", and Array%(4,9) holds value"; Array%(4, 9)
PRINT
PRINT "Now, you try it.  Choose a row and column to see what value is stored there."
PRINT "Type a number for the row and one for the column (separated by a comma).  Then,"
PRINT "press ENTER.  After you understand how the array elements are stored, press"
PRINT "ENTER alone to put this array into EMS memory and continue the demonstration."

DO
  GOSUB DataEntry
  IF PrintIt THEN
     LOCATE 22, 30
     PRINT "Array%("; QPStrI$(Row); ", "; QPStrI$(Column); ") ="; Array%(Row, Column)
     COLOR 0, 7: LOCATE 22, 55: PRINT " Press a key to try again ": COLOR 7, 0
     Z$ = INPUT$(1)
  END IF
LOOP UNTIL LEN(ArrayEl$) = 0

CALL PutArray2Ems       ' Next, place the array into expanded memory




' ********** Demonstrate how to retrieve an EMS array element  **********

CALL ClearScr0(14, 1, 24, 80, -1)   ' Clear lower half of the screen
LOCATE 16, 1
PRINT "Now that the array is in EMS memory, let's retrieve some values. "
PRINT "Choose the row and column of the value to be retrieved.  Type a number"
PRINT "for the row and one for the column (separated by a comma).  Then,"
PRINT "press ENTER.  Press ENTER alone to continue the demonstration."

DO
  GOSUB DataEntry
  IF PrintIt THEN
     CALL GetEl(Row, Column, ArrayElement%)
     LOCATE 22, 30
     PRINT "Array%("; QPStrI$(Row); ", "; QPStrI$(Column); ") ="; ArrayElement%
     COLOR 0, 7: LOCATE 22, 55: PRINT " Press a key to try again ": COLOR 7, 0
     Z$ = INPUT$(1)
  END IF
LOOP UNTIL LEN(ArrayEl$) = 0




' ********** Demonstrate how to put a value into an EMS array element  **********

CLS
PRINT "Next, we'll insert new values into the EMS array.  Choose the row & column to"
PRINT "insert the value into & press ENTER.  Type a number for value to be inserted and"
PRINT "press ENTER.  Watch the array value change.  Press ENTER alone to continue."

GOSUB PrintArray

DO
  GOSUB DataEntry
  IF PrintIt THEN
     LOCATE 23, 5: INPUT ; "Value to be inserted >", Value$
     NewValue = VAL(Value$)
     CALL SetEl(Row, Column, NewValue%) ' Set the new value
     CALL PutEms2Array                 ' Retrieve array from EMS for printing
     GOSUB PrintArray
     COLOR 0, 7: LOCATE 22, 55: PRINT " Press a key to try again ": COLOR 7, 0
     Z$ = INPUT$(1)
     LOCATE 23, 1: PRINT STRING$(79, 32);
  END IF
LOOP UNTIL LEN(ArrayEl$) = 0




' ********** Demonstrate how to get an entire row from an EMS array  **********

CLS
PRINT "Next, we'll get an entire row of values from the EMS array.  Choose the"
PRINT "row (0 to 5) to be retrieved and press ENTER.  Press ENTER alone to continue."

GOSUB PrintArray

DO
A:  LOCATE 22, 1: PRINT STRING$(80, 32): LOCATE 22, 5
    INPUT ; "Row to retrieve  >", Row$
    IF LEN(Row$) = 0 THEN EXIT DO
    Row = VAL(Row$)
    IF Row < RowLBound OR Row > NumRows THEN
       LOCATE 22, 30: PRINT "( Row value must be between"; RowLBound; "and"; NumRows; ")"
       CALL Pause(40)
       CALL ClearBuf
       GOTO A
    END IF

    CALL GetRow(Row)
    LOCATE 19, 2: PRINT "Row"; Row; TAB(10);   ' Print the row retrieved
    FOR J = ColLBound TO NumCols
        IF ReturnRow%(J) < 10 THEN PRINT "  ";
        IF ReturnRow%(J) > 9 AND ReturnRow%(J) < 100 THEN PRINT " ";
        PRINT ReturnRow%(J);
    NEXT
    COLOR 0, 7: LOCATE 22, 55: PRINT " Press a key to try again ": COLOR 7, 0
    Z$ = INPUT$(1)
LOOP



' ********** Demonstrate how to get an entire column from an EMS array  **********

CLS
PRINT "Next, we'll get an entire colunm of values from the EMS array.  Choose the"
PRINT "column (0 to 10) to retrieve & press ENTER.  Press ENTER alone to continue."

GOSUB PrintArray

DO
B:  LOCATE 22, 1: PRINT STRING$(80, 32): LOCATE 22, 5
    INPUT ; "Column to retrieve  >", Col$
    IF LEN(Col$) = 0 THEN EXIT DO
    Col = VAL(Col$)
    IF Col < ColLBound OR Col > NumCols THEN
       LOCATE 22, 30: PRINT "( Column value must be between"; ColLBound; "and"; NumCols; ")"
       CALL Pause(40)
       CALL ClearBuf
       GOTO B
    END IF
    CALL GetCol(Col)
    LOCATE 19, 2: PRINT "Col"; Col; TAB(10);    ' Print the column retrieved
    FOR I = RowLBound TO NumRows
        IF ReturnCol%(I) < 10 THEN PRINT "  ";
        IF ReturnCol%(I) > 9 AND ReturnCol%(I) < 100 THEN PRINT " ";
        PRINT ReturnCol%(I);
    NEXT
    COLOR 0, 7: LOCATE 22, 55: PRINT " Press a key to try again ": COLOR 7, 0
    Z$ = INPUT$(1)
LOOP



' ********** Demonstrate how to swap 2 rows in an EMS array  **********

CLS
PRINT "Next, we'll show how to swap 2 rows in the EMS array.  Type 2 row"
PRINT "numbers to be swapped (separated by a comma) and press ENTER."
PRINT "Press ENTER alone to continue."

GOSUB PrintArray

DO
  GOSUB RowSwapDataEntry
  IF PrintIt THEN
     CALL Swap2Rows(Row1, Row2)
     CALL PutEms2Array                 ' Retrieve array from EMS for printing
     GOSUB PrintArray
     COLOR 0, 7: LOCATE 22, 55: PRINT " Press a key to try again ": COLOR 7, 0
     Z$ = INPUT$(1)
  END IF
LOOP UNTIL LEN(ArrayEl$) = 0



' ********** Demonstrate how to swap 2 columns in an EMS array  **********

CLS
PRINT "Finally, we'll show how to swap 2 columns in the EMS array.  Type 2 column"
PRINT "numbers to be swapped (separated by a comma) and press ENTER."
PRINT "Press ENTER alone to continue."

GOSUB PrintArray

DO
  GOSUB ColumnSwapDataEntry
  IF PrintIt THEN
     CALL Swap2Cols(Col1, Col2)
     CALL PutEms2Array                 ' Retrieve array from EMS for printing
     GOSUB PrintArray
     COLOR 0, 7: LOCATE 22, 55: PRINT " Press a key to try again ": COLOR 7, 0
     Z$ = INPUT$(1)
  END IF
LOOP UNTIL LEN(ArrayEl$) = 0

CALL EmsRelMem(EmsArrayHandle%)  '  Release EMS memory before ending program

END



'  ************************************************************************
'  ***      The following subroutines are used for purposes of this     ***
'  ***       demonstration only, and are not necessary when using       ***
'  ***               these routines in your own programs.               ***
'  ************************************************************************

PrintArray:

     COLOR 9: LOCATE 5, 1: PRINT TAB(10);
     FOR J = ColLBound TO NumCols
        IF J < 10 THEN PRINT "  ";
        IF J > 9 AND J < 100 THEN PRINT " ";
        PRINT J;
     NEXT
     PRINT : PRINT
     FOR I = RowLBound TO NumRows
        COLOR 9
        PRINT TAB(5); I; TAB(10);
        COLOR 7
        FOR J = ColLBound TO NumCols
           IF Array%(I, J) < 10 THEN PRINT "  ";
           IF Array%(I, J) > 9 AND Array%(I, J) < 100 THEN PRINT " ";
           PRINT Array%(I, J);
        NEXT
        PRINT
     NEXT
     RETURN

DataEntry:

  LOCATE 22, 1: PRINT STRING$(80, 32): LOCATE 22, 5
  LINE INPUT ; "Row, Column  >"; ArrayEl$
  IF LEN(ArrayEl$) = 0 THEN
     PrintIt = 0
     RETURN
  END IF
  CommaPosn% = QInstr%(1, ArrayEl$, ",")
  IF CommaPosn% = 0 THEN
     LOCATE 22, 30
     PRINT "You forgot the comma."
     CALL Pause(25)
     CALL ClearBuf
     PrintIt = 0
  ELSE
     Row = QPValI%(QPLeft$(ArrayEl$, CommaPosn% - 1))
     Column = QPValI%(QPRight$(ArrayEl$, LEN(ArrayEl$) - CommaPosn%))
     IF Row < RowLBound OR Row > NumRows THEN
       LOCATE 22, 30: PRINT "( Row value must be between"; RowLBound; "and"; NumRows; ")"
        CALL Pause(40)
        CALL ClearBuf
        PrintIt = 0
     ELSEIF Colunm < ColLBound OR Column > NumCols THEN
       LOCATE 22, 30: PRINT "( Column value must be between"; ColLBound; "and"; NumCols; ")"
        CALL Pause(40)
        CALL ClearBuf
        PrintIt = 0
     ELSE
        PrintIt = -1
     END IF
  END IF
  RETURN

RowSwapDataEntry:

  LOCATE 22, 1: PRINT STRING$(80, 32): LOCATE 22, 5
  LINE INPUT ; "Row1, Row2  >"; ArrayEl$
  IF LEN(ArrayEl$) = 0 THEN
     PrintIt = 0
     RETURN
  END IF

  CommaPosn% = QInstr%(1, ArrayEl$, ",")
  IF CommaPosn% = 0 THEN
     LOCATE 22, 30
     PRINT "You forgot the comma."
     CALL Pause(25)
     CALL ClearBuf
     PrintIt = 0
  ELSE
     Row1 = QPValI%(QPLeft$(ArrayEl$, CommaPosn% - 1))
     Row2 = QPValI%(QPRight$(ArrayEl$, LEN(ArrayEl$) - CommaPosn%))
     IF Row1 < RowLBound OR Row1 > NumRows OR Row2 < RowLBound OR Row2 > NumRows THEN
        LOCATE 22, 30: PRINT "( Row value must be between"; RowLBound; "and"; NumRows; ")"
        CALL Pause(40)
        CALL ClearBuf
        PrintIt = 0
     ELSE
        PrintIt = -1
     END IF
  END IF
  RETURN

ColumnSwapDataEntry:

  LOCATE 22, 1: PRINT STRING$(80, 32): LOCATE 22, 5
  LINE INPUT ; "Column1, Column2  >"; ArrayEl$
  IF LEN(ArrayEl$) = 0 THEN
     PrintIt = 0
     RETURN
  END IF
  CommaPosn% = QInstr%(1, ArrayEl$, ",")
  IF CommaPosn% = 0 THEN
     LOCATE 22, 30
     PRINT "You forgot the comma."
     CALL Pause(25)
     CALL ClearBuf
     PrintIt = 0
  ELSE
     Col1 = QPValI%(QPLeft$(ArrayEl$, CommaPosn% - 1))
     Col2 = QPValI%(QPRight$(ArrayEl$, LEN(ArrayEl$) - CommaPosn%))
     IF Col1 < ColLBound OR Col1 > NumCols OR Col2 < ColLBound OR Col2 > NumCols THEN
        LOCATE 22, 30: PRINT "( Column value must be between"; ColLBound; "and"; NumCols; ")"
        CALL Pause(40)
        CALL ClearBuf
        PrintIt = 0
     ELSE
        PrintIt = -1
     END IF
  END IF
  RETURN

FUNCTION Element& (Row, Column) STATIC

'  NumRows  = number of rows in array  - (SHARED with main module)
'      Row  = Row index to be searched  - (Passed in the function call)
'   Column  = Column index to be searched  - (Passed in the function call)
' RowLBound = Lower bound on the array's row index  - (SHARED with main module)
' ColLBound = Lower bound on the array's column index  - (SHARED with main module)

' The Element& computation first adds (1-RowLBound)  to the number of rows to take into
' account the zeroth row of the array (if dimensioned, if not dimensioned, (1-RowLBound)
' evaluates to zero, and adds no offset.  Next, this sum is multiplied by the element's
' column index.  Then the element's row index is added.  The addition of the final
' quantity (1-ÿColLBound) adjusts for the zeroth element in each column of the array (if
' dimensioned).
 

   Element& = (NumRows + 1 - RowLBound) * CLNG(Column) + CLNG(Row) + 1 - ColLBound

END FUNCTION

SUB GetCol (Column) STATIC            ' Get a column of elements
    FOR I = RowLBound TO NumRows
       CALL GetEl(I, Column, ReturnCol%(I))
    NEXT
END SUB

SUB GetEl (Row, Column, ArrayElement%)   ' Get a single EMS array element

'  ArrayElement% will hold the value after we get it from the EMS array.
'  Element&(Row, Column) will compute the correct EMS array element based
'  on the Row and Column values we enter.

CALL EmsGet1El(SEG ArrayElement%, ElSize%, Element&(Row, Column), EmsArrayHandle%)
END SUB

SUB GetRow (Row) STATIC         ' Get a row of elements
    FOR J = ColLBound TO NumCols
       CALL GetEl(Row, J, ReturnRow%(J))
    NEXT
END SUB

SUB PutArray2Ems STATIC      ' Put an entire RAM array into EMS

'  RowLBound and ColLBound are the lower bound values of the row and
'  column indexes (respectively) of Array().  Do NOT put a type-declaration
'  suffix on the array name.

    CALL Array2Ems(SEG Array(RowLBound, ColLBound), ElSize%, NumEls&, EmsArrayHandle%)
END SUB

SUB PutEms2Array STATIC     ' Move an entire array from EMS into a RAM array

'  RowLBound and ColLBound are the lower bound values of the row and
'  column indexes (respectively) of Array().  Do NOT put a type-declaration
'  suffix on the array name.

    CALL Ems2Array(SEG Array(RowLBound, ColLBound), ElSize%, NumEls&, EmsArrayHandle%)
END SUB

SUB SetEl (Row, Column, NewValue%) STATIC   ' Set the value of an EMS array element

'  NewValue% holds the value we want to insert into the EMS array element.
'  Element&(Row, Column) will compute the correct EMS array element based
'  on the Row and Column values we enter.

    CALL EmsSet1El(SEG NewValue%, ElSize%, Element&(Row, Column), EmsArrayHandle%)
END SUB

SUB Swap2Cols (Col1, Col2) STATIC     ' Swap two columns in an EMS array

'  Retrieve a pair of column elements at a time from EMS, swap them in RAM,
'  and reinsert them into the EMS array.  Then loop for the next pair.

     FOR I = RowLBound TO NumRows
        CALL GetEl(I, Col1, ArrayElement1%)  '  use only these three
        CALL GetEl(I, Col2, ArrayElement2%)  '  lines of code to swap
        SWAP ArrayElement1%, ArrayElement2%  '  any two column elements.
        CALL SetEl(I, Col1, ArrayElement1%)
        CALL SetEl(I, Col2, ArrayElement2%)
     NEXT
END SUB

SUB Swap2Rows (Row1, Row2) STATIC      ' Swap two rows in an EMS array
     FOR J = ColLBound TO NumCols

'  Retrieve a pair of row elements at a time from EMS, swap them in RAM,
'  and reinsert them into the EMS array.  Then loop for the next pair.

        CALL GetEl(Row1, J, ArrayElement1%)  '  use only these three
        CALL GetEl(Row2, J, ArrayElement2%)  '  lines of code to swap
        SWAP ArrayElement1%, ArrayElement2%  '  any two row elements.
        CALL SetEl(Row1, J, ArrayElement1%)
        CALL SetEl(Row2, J, ArrayElement2%)
     NEXT
END SUB

