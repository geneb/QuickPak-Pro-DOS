'******** KEYDOWN.BAS

DEFINT A-Z

'NOTE: Keydown does not work with QuickBASIC 4.0 or earlier.

DECLARE FUNCTION KeyDown% ()

CALL InstallKeyDown             'KeyDown must be installed before it is used
CLS
PRINT "Press and release keys, and watch the KeyDown status."
PRINT "Press Escape when you are finished."

DO
  LOCATE 10, 1
  PRINT KeyDown%
LOOP UNTIL INKEY$ = CHR$(27)

CALL DeinstallKeyDown           'Deinstalling is needed only within QBX (PDS)
                                'You can ignore this step with QuickBASIC 4.5
