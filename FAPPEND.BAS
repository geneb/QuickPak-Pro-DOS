'******** FAppend.Bas - shows how to open a QuickPak Binary file for Append

'Copyright (c) 1989 Ethan Winer


DEFINT A-Z
DECLARE SUB FClose (Handle)
DECLARE SUB FCreate (FileName$)
DECLARE SUB FGet (Handle, Destination$)
DECLARE SUB FOpen (FileName$, Handle)
DECLARE SUB FPut (Handle, Source$)
DECLARE SUB FSeek (Handle, Offset&)
DECLARE SUB KillFile (FileName$)
DECLARE SUB QPrint (Work$, Colr, Page)

DECLARE FUNCTION DOSError% ()
DECLARE FUNCTION FLof& (Handle)
DECLARE FUNCTION WhichError% ()
DECLARE FUNCTION ErrorMsg$ (ErrNumber)

CLS

F$ = "FAppend.Tst"              'this is the file name we'll use for testing
FCreate F$                      'create the file
IF DOSError% THEN               'see if an error occurred creating the file
   PRINT ErrorMsg$(WhichError%) 'the only likely error is a write-protected
   END                          '  disk, an open drive door, or maybe even a
END IF                          '  full directory

FOpen F$, Handle                'open for QuickPak Professional Binary

FPut Handle, "This is the first line of text." + CHR$(13) + CHR$(10)
IF DOSError% THEN               'the only likely error here would be a
   PRINT ErrorMsg$(WhichError%) '  full disk
   END
END IF

FClose Handle                   'close the file so we can show how to append

FOpen F$, Handle                'now open it again
FSeek Handle, FLof&(Handle)     'seek to the end and write a second line
FPut Handle, "This is the second line of text." + CHR$(13) + CHR$(10)

FSeek Handle, 0&                'seek to the beginning of the file
Show$ = SPACE$(FLof&(Handle))   'make a string long enough to hold entire file
FGet Handle, Show$              'get the file to show it worked
QPrint "{" + Show$ + "}", 7, -1 'use QPrint so CHR$(13) and CHR$(10) will show

FClose Handle                   'close the file
KillFile F$                     'and erase the clutter

