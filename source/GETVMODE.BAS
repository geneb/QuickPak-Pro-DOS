'********** GetVMode.Bas - returns info about the current video mode

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z
DECLARE SUB GetVMode (Mode, Page, PageSize, Rows, Columns)

GetVMode Mode, Page, PageSize, Rows, Columns

CLS
PRINT "The current video mode is"; Mode
PRINT "BASIC is currently viewing page"; Page
PRINT "The size of each page is"; PageSize; "bytes"
IF Mode < 4 OR Mode = 7 THEN                            'GetVMode reports the
   PRINT "There are"; Rows; "rows on the screen"        'rows and columns for
   PRINT "There are"; Columns; "columns"                'text modes ONLY
END IF

