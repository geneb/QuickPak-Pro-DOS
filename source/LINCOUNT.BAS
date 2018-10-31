'********** LinCount.Bas - demos counting the number of lines in a text file

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z
DECLARE FUNCTION LineCount% (FileName$, Buffer$)
DECLARE FUNCTION DOSError% ()
DECLARE FUNCTION WhichError% ()
DECLARE FUNCTION ErrorMsg$ (ErrNum)


CLS
INPUT "Enter the name of a text file: ", FileName$

Count = LineCount%(FileName$, SPACE$(4096))

IF DOSError% THEN
   PRINT ErrorMsg$(WhichError%); " reading file "; FileName$
ELSE
   PRINT FileName$; " has"; Count; "lines in it."
END IF

