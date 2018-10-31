'********* WordWrap.Bas - prints long strings with word wrap

'Copyright (c) 1988 Ethan Winer


DEFINT A-Z
DECLARE SUB WordWrap (X$, Wide)

CLS

A$ = "This is the theme to Garry's show, the opening theme to Garry's show.  "
B$ = "Garry called me up and asked if I would write his theme song.  "
C$ = "I'm almost halfway finished, how do you like it so far.  "
D$ = "How do you like the theme to Garry's show?  "
E$ = "This is the theme to Garry's show, the opening theme to Garry's show.  "
F$ = "This is the music that you hear as you watch the credits.  "
G$ = "We're almost to the part where I start to whistle.  "
H$ = "Then we'll watch It's Garry Shandling's show. "

W$ = A$ + B$ + C$ + D$ + E$ + F$ + G$ + H$
PRINT W$
PRINT
Wide = 60               'the maximum width of the display
WordWrap W$, Wide

SUB WordWrap (X$, Wide%)

    Length% = LEN(X$)           'remember the length
    Pointer% = 1                'start at the beginning of the string

    'scan a block of eighty characters backwards, looking for a blank
    'stop at the first blank, or if we reached the end of the string
    DO
       FOR X% = Pointer% + Wide% TO Pointer% STEP -1
           IF MID$(X$, X%, 1) = " " OR X% = Length% + 1 THEN
              'LOCATE , LeftMargin      'optional to tab in the left edge
              PRINT MID$(X$, Pointer%, X% - Pointer%);
              'LPRINT [TAB(LeftMargin)]; MID$(X$, Pointer%, X% - Pointer%)
              Pointer% = X% + 1
              WHILE MID$(X$, Pointer%, 1) = " "
                 Pointer% = Pointer% + 1'swallow extra blanks to the next word
              WEND
              IF POS(0) > 1 THEN PRINT  'if the cursor didn't wrap next line
              EXIT FOR                  'done with this block
           END IF
       NEXT
    LOOP WHILE Pointer% < Length%       'loop until done

END SUB

