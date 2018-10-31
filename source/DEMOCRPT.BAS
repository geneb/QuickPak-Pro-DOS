'********** DEMOCRPT.BAS - demo to encrypt/decrypt strings using a password

'Copyright (c) 1987 Ethan Winer


DEFINT A-Z
DECLARE SUB Encrypt2 (S$, PW$)
DECLARE SUB QPrint (X$, Colr, Page)     'need QPrint to be able to display
                                        'ALL of the possible ASCII codes

CLS
LINE INPUT "String to encrypt: ", Secret$
LINE INPUT "         Password: ", Password$
PRINT

CALL Encrypt2(Secret$, Password$)
PRINT "The encrypted string is: ";
CALL QPrint(Secret$, 7, -1)

PRINT
CALL Encrypt2(Secret$, Password$)       'encrypting a second time restores it
PRINT "The original: "; Secret$

