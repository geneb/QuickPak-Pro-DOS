'********* DEMOTSRT.BAS - demonstrates the TextSort text file sorting routine

'Copyright (c) 1994 Ethan Winer


DEFINT A-Z
DECLARE FUNCTION ErrorMsg$ (ErrorNum)
DECLARE FUNCTION TextSort% (InFile$, OutFile$)

CLS
INPUT "Enter the name of the text file to sort: ", InFile$
INPUT "Enter a name for the sorted output file: ", OutFile$
PRINT

ErrCode = TextSort%(InFile$, OutFile$)
IF ErrCode THEN
  PRINT "Error"; ErrCode; "occurred: "; ErrorMsg$(ErrCode)
  END
END IF

OPEN OutFile$ FOR INPUT AS #1           'prove the sort worked
DO WHILE NOT EOF(1)
  LINE INPUT #1, Work$
  PRINT Work$
  IF LEN(INKEY$) THEN                   'pause/resume on any key press
    WHILE LEN(INKEY$) = 0: WEND
  END IF
LOOP
CLOSE

