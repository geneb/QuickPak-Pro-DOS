'********** FASTFILE.BAS - loads and saves files to and from string arrays

'Copyright (c) 1989 Don Malin


DEFINT A-Z

DECLARE FUNCTION DOSError% ()
DECLARE FUNCTION FastLoadInt% (FileName$)
DECLARE FUNCTION FindLast% (BYVAL Address, NumEls)
DECLARE FUNCTION FLof& (Handle)
DECLARE FUNCTION NumStrings% (SEG Element, NumBytes AS ANY)
DECLARE FUNCTION StringSize& (BYVAL Address, Lines)
DECLARE FUNCTION WhichError% ()

DECLARE SUB FClose (Handle)
DECLARE SUB FCreate (FileName$)
DECLARE SUB FGetA (Handle, SEG Element, NumBytes AS ANY)
DECLARE SUB FOpen (FileName$, Handle)
DECLARE SUB FPutA (Handle, SEG Element, NumBytes AS ANY)
DECLARE SUB SetError (ErrCode)
DECLARE SUB StringRestore (Array$(), Array())
DECLARE SUB StringSave (BYVAL Address, SEG Element, NumEls)

REDIM Txt(0)            'establish the array that will hold the retrieved file

'----- Load a file into an integer array and return the number of strings
FUNCTION FastLoadInt% (FileName$) STATIC

    SHARED Txt()                                'this lets us use REDIM
    CALL FOpen(FileName$, Handle)               'open the file
    IF DOSError% THEN EXIT FUNCTION             'bail out if error
    ErrCode = 0                                 'assume no error

    Temp& = FLof&(Handle)                       'get the length of the file
    IF Temp& > FRE("") - 1280& THEN             'is there enough string space?
       ErrCode = 14                             'no, set "Out of String Space"
       GOTO ExitFn                              '  error number and bail out
    ELSEIF Temp& < 1 THEN                       'is this a Null file?
       ErrCode = 62                             'yes, set "Input Past End"
       GOTO ExitFn                              '  error and bail out
    END IF                                      '  (this is what BASIC does)

    Size = (Temp& + 1) \ 2                      'calc. the number of integer
                                                '  array elements required
    IF FRE(-1) - 1280& < Size * 2& THEN         'is there enough far memory?
       ErrCode = 7                              'no, set "Out of Memory" error
       GOTO ExitFn                              'bail out
    END IF

    REDIM Txt(1 TO Size)                        'create a temporary array
    CALL FGetA(Handle, Txt(1), Temp&)           'read the file into the array
    ErrCode = WhichError%                       'if an error, remember it
    IF NOT DOSError% THEN                       'else return number of lines
       FastLoadInt% = NumStrings%(Txt(1), Temp&)
    END IF

ExitFn:
    CALL FClose(Handle)                         'close the file
    IF NOT DOSError% THEN CALL SetError(ErrCode)  'set (or clear) the error

END FUNCTION

'
'----- Copy an integer array to a string array
SUB FastLoadStr (Text$()) STATIC

    SHARED Txt()
    CALL StringRestore(Text$(), Txt())  'StringRestore does the real work
    ERASE Txt                           'Clean up far memory

END SUB

'----- Save a string array to disk
SUB FastSave (FileName$, Text$()) STATIC
    
    NumEls = UBOUND(Text$)      'find number of active elements - these
    LoBound = LBOUND(Text$)     '  calculations accommodate any option base
    NumEls = FindLast%(VARPTR(Text$(NumEls)), NumEls) - LoBound + 1
    CALL FCreate(FileName$)             'create the file
    IF DOSError% THEN EXIT SUB          'exit if error

    '----- See how many bytes will be required in the integer array
    Bytes& = StringSize&(VARPTR(Text$(LoBound)), NumEls)
    IF Bytes& = 0 THEN EXIT SUB         'the array is empty, so we're all done
    Size = Bytes& / 2 + .1              'force round up

    IF FRE(-1) - 1280& < Size * 2& THEN 'is there enough far memory?
       CALL SetError(7)                 'no, set "Out of Memory" error
       EXIT SUB                         'bail out
    END IF

    CALL FOpen(FileName$, Handle)       'open the file for QuickPak Binary
    IF DOSError% THEN EXIT SUB          'bail out if an error occured
 
    REDIM Txt(1 TO Size)                        'make a temporary array
    CALL StringSave(VARPTR(Text$(LoBound)), Txt(1), NumEls)  'save text to the array
    CALL FPutA(Handle, Txt(1), Bytes&)          'save the Int. array to file
    SaveErr = WhichError%                       'if an error, remember it
    CALL FClose(Handle)                         'close the file
    IF NOT DOSError% THEN CALL SetError(SaveErr)   'recreate error if needed
    ERASE Txt                                   'clean up far memory

END SUB

