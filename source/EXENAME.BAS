'********** ExeName.Bas - gets the full path and name of the current program

'Copyright (c) 1988 Ethan Winer


'ExeName returns the fully qualified name of the currently executing program.
'If you run this from within the QuickBASIC environment it will of course
'return "QB.EXE" along with the path from which it was loaded.  It is worth
'mentioning that the drive letter and colon are not always included in the
'name ExeName returns.  The only time we've observed this is when the program
'was not in the current directory but was found via the PATH setting, and the
'path did not include a drive letter:
'
'    PATH = C:\DOS;\C:\UTIL
'or
'    PATH = \DOS;\UTIL
'
'In the first example above, the drive letter will be included in the full
'name returned by ExeName.  In the second example it will not.  Understand
'that this applies only to those situations where the program was found via
'the DOS PATH setting.  If the user precedes the file name with an explicit
'path as in \QB4\MYPROG, the drive letter and colon will be present.  Also
'understand that none of this has anything to do with the way ExeName was
'written.  ExeName simply returns the information provided by DOS, and it is
'DOS who forgot to include the drive.
'
'The example below shows how to obtain the drive letter if it is not present.
'This should be done early in the program, before your user has a chance to
'SHELL or change the current drive.


DEFINT A-Z
DECLARE FUNCTION ExeName$ ()
DECLARE FUNCTION GetDrive% ()

CLS
FullName$ = UCASE$(ExeName$)    'capitalize it if you care
IF LEN(FullName$) THEN          'ExeName$ returns a null if less than DOS 3.0
   PRINT "The full name of the currently executing program is ";
   IF INSTR(FullName$, ":") = 0 THEN    'no drive present, so get default
      PRINT CHR$(GetDrive%); ":";
   END IF
   PRINT FullName$
ELSE
   PRINT "This function requires DOS 3.0 or later."
END IF

