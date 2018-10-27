'********* RptKey.Bas - detects multiple repeats of the same key if extended

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z
DECLARE SUB RptKey (Char, Count)

CLS
LOCATE 20, 1, 0
PRINT "Press any Alt, Ctrl, or Shift key a bunch of times and then let it go."
PRINT "Press Escape when finished."

DO
   RptKey Char, Count
   IF Char THEN
      LOCATE 5, 1
      IF Count THEN
         PRINT "Extended key:"; Char; "was pressed"; Count; "times"; TAB(79);
      ELSE
         PRINT "Normal key: "; CHR$(Char); TAB(79);
         IF Char = 27 THEN END
      END IF
   END IF
LOOP

