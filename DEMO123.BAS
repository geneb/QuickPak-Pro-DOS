'********** DEMO123.BAS - demonstrates reading/writing files in Lotus 123 format

'Copyright (c) 1989 Ethan Winer


'This program provides an example of both reading and creating files that
'may be processed by Lotus 123.  As such, it is not intended to serve as a
'complete set of tools, rather it merely shows the steps that are needed.
'
'If you select "Create" when this program is run, it will write a worksheet
'file named SAMPLE.WKS suitable for reading into any version of Lotus 123.
'This sample file contains an assortment of labels and values.  If you select
'"Read", the program will prompt for the name of a worksheet file.  Either
'type the name of an existing Lotus file, or press Enter to see a list of
'worksheet files.  We have not provided any sample files, so you must provide
'your own, or first create one using this program.
'
'This program was derived from an article that appeared in PC Magazine in
'the December 13, 1988 issue (Volume 7, Number 21).  Press F2 to view the
'"Subprogram" named Doc123 for a brief discussion of the Lotus file format.
'All of the research for this program was provided by Philip Martin Valley.
'
'NOTE: to read and write files for Lotus 1-2-3 version 3.0 change the file
'extension to .WK1 and set the version number to 1030.  Thanks to Marcus
'Lyon of London, England for this tip.


DEFINT A-Z
DECLARE FUNCTION Exist% (FileSpec$)
DECLARE SUB GetFormat (Frmat, Row, Column)
DECLARE SUB WriteColWidth (Column, ColWidth)
DECLARE SUB WriteInteger (Row, Column, ColWidth, Temp)
DECLARE SUB WriteLabel (Row, Column, ColWidth, Msg$)
DECLARE SUB WriteNumber (Row, Column, ColWidth, Fmt$, Number#)

DIM SHARED CellFmt AS STRING * 1        'allows reading one byte
DIM SHARED ColNum(40)                   'maximum number of columns to write
DIM SHARED FileNum                      'the file number to use

CLS
PRINT "Read an existing 123 file or Create a sample file (R/C)? ";
LOCATE , , 1
DO
   X$ = UCASE$(INKEY$)
LOOP UNTIL X$ = "R" OR X$ = "C"
LOCATE , , 0
PRINT X$

IF X$ = "R" THEN        '***** read an existing file

   DO
     INPUT "Lotus file to read (press Enter to display a list): ", FileName$
     IF FileName$ = "" THEN
       IF Exist%("*.WK?") THEN
         FILES "*.WK?"
       ELSE
         PRINT "No sample files, press Enter and then select Create sample."
         INPUT "", BS$
         RUN
       END IF
     END IF
   LOOP UNTIL LEN(FileName$)

   IF INSTR(FileName$, ".") = 0 THEN FileName$ = FileName$ + ".WKS"
   PRINT

   FileNum = FREEFILE                       'obtain next available file handle
   OPEN FileName$ FOR BINARY AS #FileNum    'open the file for Binary access

   DO UNTIL Opcode = 1                  'until Lotus "End of File" Opcode

      GET FileNum, , Opcode             'get the next opcode
      GET FileNum, , Length             'and length of the data that follows
  
      SELECT CASE Opcode                'handle the data according to its type

        CASE 0                          'Beginning of file record and version
          GET FileNum, , Temp           'Temp holds the version number

          IF Temp < 1028 OR Temp > 1030 THEN  'test this if the file might
            PRINT "NOT a Lotus File!"         '  not be a valid Lotus file
            END
          END IF

          PRINT "Beginning of file:  Lotus "; 'Version number is the only
            SELECT CASE Temp                  '  information in this record
              CASE 1028
                PRINT "123 version 1.0 or 1A"
              CASE 1029
                PRINT "Symphony version 1.0"
              CASE 1030
                PRINT "123 version 2.0, 2.1, or Symphony version 1.1"
            END SELECT
     
     
        CASE 12                 'Blank - NOTE: Lotus saves blank cells only
                                '  if they are formatted or protected
          CALL GetFormat(Frmat, Row, Column)
          PRINT "Blank:      Format ="; Frmat, "Row ="; Row, "Col ="; Column


        CASE 13                'Integer
          CALL GetFormat(Frmat, Row, Column)
          GET FileNum, , Temp
          PRINT "Integer:    Format ="; Frmat, "Row ="; Row, "Col ="; Column, "Value ="; Temp


        CASE 14                'Floating point
          CALL GetFormat(Frmat, Row, Column)
          GET FileNum, , Number#
          PRINT "Number:     Format ="; Frmat, "Row ="; Row, "Col ="; Column, "Value ="; Number#

     
        CASE 15                'Label
          CALL GetFormat(Frmat, Row, Column)
          Info$ = SPACE$(Length - 6)    'create a string to hold the label
                                        '6 is subtracted to exclude the
                                        '  Format, Column, Row, and 0 bytes
                                        '  that were included in the original
                                        '  length byte (already gotten by the
                                        '  GetFormat routine)
          GET FileNum, , Info$          'get the label text
          GET FileNum, , CellFmt$       'gobble up the trailing CHR$(0) byte
          PRINT "Label:      Format ="; Frmat, "Row ="; Row, "Col ="; Column, Info$

     
        CASE 16                'Formula
          CALL GetFormat(Frmat, Row, Column)
          GET FileNum, , Number#        'get the cell's value
          GET FileNum, , Length         'get length of formula "text"
          SEEK FileNum, SEEK(FileNum) + Length   'skip over the formula
                                        'the formula is "tokenized" in reverse
                                        'Polish notation - not a pretty story
        PRINT "Formula:    Format ="; Frmat, "Row ="; Row, "Col ="; Column, Number#

     
        CASE ELSE               'anything else merely relates to the way the
                                '  spreadsheet operates (recalc order, print
                                '  ranges, and so forth)
          Dummy$ = SPACE$(Length)       'skip over the unwanted record
          GET FileNum, , Dummy$
          PRINT "Opcode: "; Opcode      'show its Opcode just for fun

      END SELECT
  
      '------ pause when the screen fills
      IF CSRLIN > 21 THEN
        PRINT : PRINT "Press <ESC> to end or any other key for more . . ."
        DO
          K$ = INKEY$
        LOOP UNTIL LEN(K$)
        IF K$ = CHR$(27) THEN EXIT DO
        CLS
      END IF

      Cntr = Cntr + 1           'track how many 123 records have been read

   LOOP

   PRINT "Number of Records Processed ="; Cntr
   CLOSE

ELSE    '***** write a sample file

   FileNum = FREEFILE           'get the next available file number
   OPEN "SAMPLE.WKS" FOR BINARY AS #FileNum

   Temp = 0                     'OpCode for Start of File
   PUT FileNum, , Temp
   Temp = 2                     'data length is 2 (for the following integer)
   PUT FileNum, , Temp
   Temp = 1028                  'the Lotus version number
   PUT FileNum, , Temp          '(Lotus version 1 = 1028; version 2 = 1030)

   Row = 0                      'row numbers in Lotus begin with 0, not 1
   DO
      CALL WriteLabel(Row, 0, 16, "This is a Label")    'a label
      CALL WriteLabel(Row, 1, 12, "So's This")          'another label
      CALL WriteInteger(Row, 2, 7, 12345)               'an integer
      CALL WriteNumber(Row, 3, 9, "C2", 57.23#)         'a number:  $57.23
      CALL WriteNumber(Row, 4, 9, "F5", 12.3456789#)    'another number
      CALL WriteInteger(Row, 6, 9, 99)          'it's okay to skip a column
      Row = Row + 1                             'go on to the next row
   LOOP WHILE Row < 6

   '----- Write the "End of File" record and close the file
   Temp = 1                'OpCode for End of File
   PUT FileNum, , Temp
   Temp = 0                'its Data length is zero
   PUT FileNum, , Temp

   CLOSE

END IF

SUB Doc123    'Dummy sub to separate this discussion from the example programs
'
'All Lotus 123 files are intended to be read sequentially using a Binary file
'access.  A Lotus file is comprised of individual records, and each record
'may have a varying length.  The length of a record depends on its contents,
'though most records contain a fixed-length header which describes the
'information that follows.
'
'A Lotus 123 file may contain as many as 63 different types of records.
'However, this program accommodates only those that would be of interest in
'a BASIC program.  These are Beginning of File, End of File, Integer values,
'Floating point values, Text labels, and the double precision values embedded
'within a Formula record.  The format used by the actual formulas is quite
'complex, and is not addressed in this discussion.  A complete description of
'all of the record types is contained in the excellent book, "File Formats
'for Popular PC Software" written by Jeff Walden, and published by Wiley
'Press.  (ISBN number 0-471-83671-0)
'
'Other records that will not be covered here are those that pertain to the
'structure of the worksheet itself.  For example, range names, printer setup
'strings, macro definitions, and so forth.  These are described fully in the
'above mentioned book.
'
'Regardless of the type of record being considered, each follows the exact
'same format:
'
'     Opcode, Length, Data
'
'The Opcode is always a two-byte integer which identifies the type of data
'that will follow.  For example, an Opcode of 15 indicates that the data in
'the record will be treated by 123 as a text label.  The Length is also an
'integer, and it tells the number of bytes in the Data section that follows.
'
'All of the records that pertain to a cell contain a five-byte header at the
'beginning of the data section.  These five bytes are included within the
'Length byte for the data.  The first header byte contains the formatting
'information, such as the number of decimal positions to display.  The next
'two bytes together contain the cell's row, and the following two bytes hold
'the cell's column.
'
'This header is present only in records that refer to a cell's contents.  For
'example, the Beginning and End of File records do not contain a header, nor
'do those records that describe the worksheet.  Some records such as labels
'and formulas will have a varying length, while those that contain numbers
'will be fixed depending on the type of number.  Floating point values are
'always eight bytes long, and are in the same IEEE format used by QuickBASIC
'4.0 and later.  Likewise, an integer value will always have a length of two
'bytes.  Because the Length word includes the five-byte header size, the total
'length for these examples would be 13 and 7 respectively.
'
'It is important to understand that internally, rows and columns are based at
'zero.  Even though 123 considers the leftmost row to be number 1, it is
'stored in the file as a zero.  Likewise, the first column as displayed by
'123 is labelled "A", but is identified in the file as column 0.  It is thus
'up to your program to translate the columns to the alphabetic format if you
'intend to display them as Lotus does.
'
'In the sample read program, the same steps are performed for each record.
'That is, GET is used to read the record's type, length, and data.  If the
'record type indicates that it pertains to a worksheet cell, then the five-
'byte header will also be read using the GetFormat subprogram.  Opcodes that
'are not supported by this program are simply displayed, so you will see that
'they were encountered.
'
'The sample write program performs simple formatting, and also ensures that
'a column-width record is written only once.  The table below shows the
'makeup of the formatting byte used in Lotus files:
'
'                      7  6  5  4  3  2  1  0      <-------- bits
'                      ^  ^  ^  ^  ^  ^  ^  ^
'                      |  |  |  |  |  |  |  |
' protected if set ----+  |  |  |  +--+--+--+--- number of digits
'                         +--+--+--------------- type of format (see below)
'
'
'                         0  0  0      fixed number of digits
'                         0  0  1      exponential notation
'                         0  1  0      currency
'                         0  1  1      percent
'                         1  0  0      flag to add commas when displaying
'                         1  0  1      unused
'                         1  1  0      unused
'                         1  1  1      other format
'
END SUB

SUB GetFormat (Frmat, Row, Column)

  GET FileNum, , CellFmt$: Frmat = ASC(CellFmt$)
  GET FileNum, , Column
  GET FileNum, , Row

END SUB

SUB WriteColWidth (Column, ColWidth)

  IF NOT ColNum(Column) THEN            'if width record not already written
    IF ColWidth = 0 THEN ColWidth = 9   'default to 9 if no value
    Temp = 8
    PUT FileNum, , Temp
    Temp = 3
    PUT FileNum, , Temp
    PUT FileNum, , Column
    Temp$ = CHR$(ColWidth)
    PUT FileNum, , Temp$
    ColNum(Column) = -1                 'show we did this one for later
  END IF

END SUB

SUB WriteInteger (Row, Column, ColWidth, Integ)

  Temp = 13                     'OpCode for an integer
  PUT FileNum, , Temp
  Temp = 7                      'Length + 5 byte header
  PUT FileNum, , Temp
  Temp$ = CHR$(127)             'the format portion of the header
  PUT FileNum, , Temp$          '(use CHR$(255) for a protected field)
  PUT FileNum, , Column
  PUT FileNum, , Row
  PUT FileNum, , Integ

  CALL WriteColWidth(Column, ColWidth)

END SUB

SUB WriteLabel (Row, Column, ColWidth, Msg$)

  IF LEN(Msg$) > 240 THEN Msg$ = LEFT$(Msg$, 240)   '240 is maximum length

  Temp = 15                     'OpCode for a label
  PUT FileNum, , Temp
  Temp = LEN(Msg$) + 7          'Length + 5-byte header + "'" + CHR$(0) byte
  PUT FileNum, , Temp
  Temp$ = CHR$(127)             '127 is default format for unprotected cell
  PUT FileNum, , Temp$
  PUT FileNum, , Column
  PUT FileNum, , Row
  Temp$ = "'" + Msg$ + CHR$(0)  'NOTE:  "'" means label will be left aligned

  PUT FileNum, , Temp$
  CALL WriteColWidth(Column, ColWidth)

END SUB

SUB WriteNumber (Row, Column, ColWidth, Fmt$, Number#)

  IF LEFT$(Fmt$, 1) = "F" THEN                  'fixed ...
    Frmat$ = CHR$(0 + VAL(RIGHT$(Fmt$, 1)))     'number of decimal places
  ELSEIF LEFT$(Fmt$, 1) = "C" THEN              'currency ...
    Frmat$ = CHR$(32 + VAL(RIGHT$(Fmt$, 1)))    'number of decimal places
  ELSEIF LEFT$(Fmt$, 1) = "P" THEN              'percent ...
    Frmat$ = CHR$(48 + VAL(RIGHT$(Fmt$, 1)))    'number of decimal places
  ELSE
    Frmat$ = CHR$(127)                          'use default format
   'Frmat$ = CHR$(255)                          'optional to protect cell
  END IF
     
  Temp = 14
  PUT FileNum, , Temp
  Temp = 13
  PUT FileNum, , Temp
  PUT FileNum, , Frmat$
  PUT FileNum, , Column
  PUT FileNum, , Row
  PUT FileNum, , Number#
  
  CALL WriteColWidth(Column, ColWidth)

END SUB

