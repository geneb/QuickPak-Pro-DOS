'*********** FLInput.Bas - QuickPak Professional LINE INPUT style file input

'Copyright (c) 1989 Ethan Winer


DEFINT A-Z
DECLARE SUB FClose (Handle)
DECLARE SUB FOpen (FileName$, Handle)

DECLARE FUNCTION DOSError% ()
DECLARE FUNCTION ErrorMsg$ (ErrNumber)
DECLARE FUNCTION FLInput$ (Handle, Buffer$)
DECLARE FUNCTION WhichError% ()


BufSize = 82                            'enough to read up to 80 chars + CRLF
Buffer$ = SPACE$(BufSize)               '  (or use whatever is appropriate)

CLS
LINE INPUT "Enter the name of a file to read: ", FileName$

FOpen FileName$, Handle                 'open for QuickPak Professional Binary
IF DOSError% THEN                       'see if there was an error
   PRINT ErrorMsg$(WhichError%)         'show what happened
   END                                  'and then end
END IF

DO                                      'the main file read loop
   Temp$ = FLInput$(Handle, Buffer$)    'get a line of input
   WHILE WhichError% = 83               'a "Buffer too small" error means
      Temp$ = Temp$ + FLInput$(Handle, Buffer$)     'we have to go back
   WEND                                             'and get some more
   IF DOSError% THEN EXIT DO            'exit if error (probably end of file)
   PRINT Temp$                          'otherwise, print it
LOOP

IF WhichError% <> 62 THEN               'report anything but the expected
   PRINT                                '  "End of file" error
   PRINT "Error: "; ErrorMsg$(WhichError%)
END IF

FClose Handle                           'always remember to close the file

