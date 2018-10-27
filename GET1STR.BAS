'********** Get1Str.Bas - retrieves a single string from an integer array

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z
DECLARE SUB Get1Str (Work$, SEG Element, StrNumber)
DECLARE FUNCTION FindLastSM& (SEG Element, NumBytes AS ANY)
DECLARE FUNCTION Get1String$ (Array%(), StrNumber)
DECLARE FUNCTION StrLength% (SEG Element, NumBytes AS ANY, StrNumber)

FUNCTION Get1String$ (Array(), StrNumber) STATIC

    UB = UBOUND(Array)                              'find the array bounds
    LB = LBOUND(Array)
    NumBytes& = (UB - LB + 1) * 2                   'total bytes in Array
    NumBytes& = FindLastSM&(Array(LB), NumBytes&)   'ignore extra elements

    Work$ = SPACE$(StrLength%(Array(LB), NumBytes&, StrNumber))
    CALL Get1Str(Work$, Array(LB), StrNumber)       'copy the string to Work$
    Get1String$ = Work$                             'assign the function

    Work$ = ""                                      'free up the memory

END FUNCTION

