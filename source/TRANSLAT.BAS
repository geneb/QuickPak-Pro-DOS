'********** Translat.Bas

'Translate will replace the special box characters with normal ASCII
'characters that any printer can use.

'Copyright (c) 1989 Ethan Winer


DECLARE SUB Translate (X$)

CLS
FOR X = 33 TO 254               'create a test string
    T$ = T$ + CHR$(X)
NEXT

LOCATE 5
PRINT T$                        'print the original string
PRINT

Translate T$                    'translate the extended and box characters
LOCATE 15
PRINT T$                        'print the result

LOCATE 23, , 1
PRINT "Press a key: ";          'now show Translate in context
WHILE INKEY$ = "": WEND
CLS

Top$ = "Ú" + STRING$(58, "Ä") + "¿"
Sid$ = "³" + STRING$(58, " ") + "³"
Bot$ = "À" + STRING$(58, "Ä") + "Ù"

LOCATE 5, 10
PRINT Top$
FOR X = 1 TO 5
    LOCATE , 10
    PRINT Sid$
NEXT
LOCATE , 10
PRINT Bot$

Translate Top$
Translate Sid$
Translate Bot$

LOCATE 15, 10
PRINT Top$
FOR X = 1 TO 5
    LOCATE , 10
    PRINT Sid$
NEXT
LOCATE , 10
PRINT Bot$

