'********** InStat.Bas - tells if characters are pending in the keyboard

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z
DECLARE FUNCTION InStat% ()
DECLARE SUB ClearBuf ()
DECLARE FUNCTION PeekBuf% ()

CLS : PRINT "Press any key, or Ctrl-Break to end"
LOCATE 3, , 0: PRINT "Characters pending:";

More:

   Count = InStat%
   LOCATE 3, 20
   PRINT Count
   IF Count > 10 THEN ClearBuf
   PRINT "First character pending ="; PeekBuf%; SPC(2);

GOTO More

