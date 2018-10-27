'********** STRREST.BAS - restores a string array from an integer array

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z

DECLARE FUNCTION FindLastSM& (SEG Element, NumBytes AS ANY)
DECLARE FUNCTION GetNext% (StrSeg, StrAdr, LastAdr AS ANY)
DECLARE FUNCTION NumStrings% (SEG Element, NumBytes AS ANY)
DECLARE SUB SetError (ErrNum)
DECLARE SUB StringRest (BYVAL Address, SEG Element, NumEls)

SUB StringRestore (Array$(), Array()) STATIC

    '----- Calculate the number of string elements in Array$()
    First = LBOUND(Array$)
    Last = UBOUND(Array$)

    '----- Get the segment, address, and number of active bytes in the array
    LoEl = LBOUND(Array)
    HiEl = UBOUND(Array)
    StrSeg = VARSEG(Array(LoEl))
    StrAdr = VARPTR(Array(LoEl))

    CALL SetError(0)                    'clear the WhichError function
    NumBytes& = (HiEl - LoEl + 1) * 2&
    NumBytes& = FindLastSM&(Array(LoEl), NumBytes&)
    LastAdr& = NumBytes& - VARPTR(Array(LoEl))

    '----- See if the string array has been dimensioned to enough elements
    NumStr = NumStrings%(Array(LoEl), NumBytes&)
    IF NumStr > Last - First + 1 THEN
       CALL SetError(100)               'not enough, set an error and exit
       EXIT SUB
    END IF

    '----- Make room in each string element.  The GetNext function is
    '      intended to be invoked successively, and it modifies the StrAdr
    '      variable to point to the next string in the integer array for
    '      the next time.  Do NOT use GetNext as part of a QuickBASIC watch
    '      variable/expression.
    FOR X = First TO First + NumStr - 1
        ThisLen = GetNext%(StrSeg, StrAdr, LastAdr&)
        IF ThisLen AND &H8000 THEN EXIT FOR     'GetNext returns -1 if it runs
        Array$(X) = SPACE$(ThisLen)             'out of data, "AND" is a very
    NEXT                                        'fast test for negative values

    '----- Copy the integer array into the string array
    CALL StringRest(VARPTR(Array$(First)), Array(LoEl), NumStr)

END SUB

