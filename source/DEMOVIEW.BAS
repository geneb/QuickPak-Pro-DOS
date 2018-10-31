'********** DemoView.Bas - demonstrates ViewFile

'Copyright (c) 1988 Don Malin & Crescent Software


DEFINT A-Z

DECLARE FUNCTION DosError% ()
DECLARE FUNCTION Null% (Work$)
DECLARE FUNCTION WhichError% ()
DECLARE FUNCTION ErrorMsg$ (ErrNum)
DECLARE SUB ViewFile (FileName$, NumChars, Rows, Colr, HiBit, Action)


Msg$ = SPACE$(79)                               'Message string used later

COLOR 2, 0                                      'Green on Black
CLS
LOCATE 2, 1                                     'Put dots on screen to show
PRINT STRING$(1840, 254);                       '  the screen being restored
                                                '  after ViewFile finishes.

COLOR 15, 0                                     'Bright white for messages

                                                'The view window will contain
Rows = 15                                       '  15 rows,
NumChars = 70                                   '  70 columns
Colr = 31                                       '  and will be bright white
                                                '  on blue background.

DO
    LOCATE 1, 1                                 'Get the file name
    LINE INPUT "File to display: ", F$
    IF Null%(F$) THEN END
                                                'Give directions to user
    LSET Msg$ = "  Use Arrow keys, PgUp, PgDn, Home, or Ctrl-left keys.  Escape to end."
    LOCATE 25, 1
    PRINT Msg$;

    LOCATE 4, 5                                 'Upper left corner of window
    ViewFile F$, NumChars, Rows, Colr, 0, 0     'Browse the file

    IF DosError% THEN                           'Flag if no file or bad drive
       LSET Msg$ = ErrorMsg$(WhichError%) + " - press any key to continue."
       LOCATE 25, 1
       PRINT Msg$;
       CALL WaitKey
       LSET Msg$ = ""
       LOCATE 25, 1
       PRINT Msg$;
    END IF

LOOP WHILE DosError%                            'Go back for another file

