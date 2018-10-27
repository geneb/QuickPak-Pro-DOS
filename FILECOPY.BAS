'********** FILECOPY.BAS - demonstrates the FileCopy subprogram

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z

DECLARE SUB FileCopy (Source$, Dest$, Copied, ErrFlag)
DECLARE SUB FCopy (Source$, Dest$, Buffer$, ErrCode)
DECLARE SUB ReadFile (BYVAL Address)
DECLARE SUB SetError (ErrCode)
DECLARE FUNCTION FCount% (Spec$)
DECLARE FUNCTION DOSError% ()
DECLARE FUNCTION WhichError% ()
DECLARE FUNCTION FullName$ (PartName$)

'---- please see DEMOCOPY.BAS for an example of using this routine

SUB FileCopy (Source$, Dest$, Copied, ErrCode) STATIC

    '----- Source$ may include a drive letter, a path, or wild cards
    '----- Dest$ may be a drive or path name only

    FOR X = LEN(Source$) TO 1 STEP -1   'search for a "\" or ":"
        IF MID$(Source$, X, 1) = "\" OR MID$(Source$, X, 1) = ":" THEN EXIT FOR
    NEXT
    Path$ = LEFT$(Source$, X)           'path is anything up to "\"

    IF LEN(Path$) AND RIGHT$(Path$, 1) <> "\" AND RIGHT$(Path$, 1) <> ":" THEN
       Path$ = Path$ + "\"
    END IF
   
    IF LEN(Dest$) AND RIGHT$(Dest$, 1) <> "\" AND RIGHT$(Dest$, 1) <> ":" THEN
       Dest$ = Dest$ + "\"
    END IF

    ErrCode = 1                     'an error here would be on the source
    Count = FCount%(Source$)        'count the number of matching files
    IF DOSError% THEN EXIT SUB      'the door was open or something
    IF Count = 0 THEN               'there were no matching files
       CALL SetError(53)            'show the caller that no files matched
       EXIT SUB                     'and say goodbye
    END IF

    REDIM Array$(0 TO Count)        'make an array to hold their names
    FOR X = 1 TO Count              'fill with spaces
        Array$(X) = SPACE$(12)
    NEXT
    Array$(0) = Source$             'put the spec into element zero
    CALL ReadFile(VARPTR(Array$(0)))    'and use ReadFile to get them

    IF FRE("") > 4096 THEN
       BuffLen = 4096               '4096 bytes is sufficient
    ELSE
       BuffLen = FRE(0) - 100 - 512     'take all but a few bytes
       BuffLen = (BuffLen \ 512) * 512  'round to a multiple of 512 bytes
    END IF
    Buffer$ = SPACE$(BuffLen)           'this will be FCopy's file buffer

    Copied = 0                          'track how many are actually copied
    FOR X = 1 TO Count                  'copy each file
        '-- Prevent copying a file on top of itself
        SrcName$ = FullName$(Path$ + Array$(X))     'get full path for source
        IF DOSError% THEN EXIT FOR                  'exit loop if an error
        DestName$ = FullName$(Dest$ + Array$(X))    'get full path for dest
        IF DOSError% THEN                           'if an error occurs
            ErrCode = 2                             'set errcode to dest
            EXIT FOR                                'and exit loop
        END IF
        IF SrcName$ = DestName$ THEN                'if copying onto itself
            CALL SetError(70)                       'return Permission denied
            EXIT FOR                                'and exit loop
        ELSE                                        'otherwise
            CALL FCopy(SrcName$, DestName$, Buffer$, ErrCode)  'copy the file
            IF DOSError% THEN EXIT FOR              'exit loop if an error
            Copied = Copied + 1             'show that another one was copied
        END IF
    NEXT

    Buffer$ = ""                        'free up the memory
    ERASE Array$                        '  ditto

END SUB

