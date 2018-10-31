'************ MidStrSR.Bas - demos MidStrSR.Asm

'Copyright (c) 1989 Crescent Software

'MidStrSave and ImStrRest are routines similar to the original StringSave and
'StringRestore, but they are intended for use with a MID$ portion of a string
'array.  They are not documented in the QuickPak Professional manual because
'they have no real application outside of the QEdit text editor.  In that
'program we use it to capture and restore text that has been marked in the
'column mode.  The text is maintained in a far array (Storage in the examples
'below).  We provide this demo merely for your amusement.


DEFINT A-Z

DECLARE SUB MidStrSave (BYVAL Address, NumEls, FirstChar, NumChars, SEG Storage)
DECLARE SUB MidStrRest (Buffer$, StrNumber, SEG Storage)

CLS
NumEls = 10
FirstChar = 19
NumChars = 10

DIM T$(NumEls)
DIM Storage((CLNG(NumEls) * NumChars) \ 2)

FOR X = 1 TO NumEls
    T$(X) = "String" + STR$(X) + " testing number" + STR$(X)
    PRINT T$(X)
NEXT

MidStrSave VARPTR(T$(1)), NumEls, FirstChar, NumChars, Storage(0)
PRINT
Buffer$ = SPACE$(NumChars)
FOR StrNumber = 1 TO 10
    MidStrRest Buffer$, StrNumber, Storage(0)
    PRINT "{"; Buffer$; "}"
NEXT

