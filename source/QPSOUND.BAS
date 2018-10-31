'********** QPSound.Bas - demonstrates sounds without using PLAY or SOUND

'Copyright (c) 1989 Ethan Winer


DEFINT A-Z
DECLARE SUB Chime (Number)
DECLARE SUB Pause (Ticks)
DECLARE SUB QPSound (Frequency, Duration)

CLS

'---- demo number one - glide tones

Pause 1                         'this synchronizes QPSound to the system clock
                                'you would need this only with a duration of
PRINT "Glide tones"             '1, and then only if you care that the first
PRINT                           'sound might be a bit short
FOR X = 50 TO 2000 STEP 50
    QPSound X, 1
    QPSound X * 2, 1
NEXT
Pause 15                        'wait a bit before the next demo


'---- demo number two - PLAY via DATA statements for pitch and frequency

PRINT "How much is that thing over there?"
PRINT
READ NumNotes
FOR X = 1 TO NumNotes
    READ Pitch, Length
    QPSound Pitch, Length
NEXT
Pause 15
DATA 10                         : 'number of notes to play
DATA 392, 4, 523, 4, 392, 4     : 'how much you want for that there dog?
DATA 330, 4, 262, 6, 440, 2
DATA 392, 2, 330, 2, 392, 4, 294, 8


'---- demo number three - PLAY via DATA statements for pitch and frequency

PRINT "Ms. PackMan"
PRINT
READ NumNotes
FOR X = 1 TO NumNotes
    READ Pitch, Length
    IF Pitch THEN               'this lets you use a pitch of zero to pause
       QPSound Pitch, Length
    ELSE
       Pause Length
    END IF
NEXT
Pause 15
DATA 23
DATA 262, 2, 294, 2, 330, 2, 262, 2, 294, 4, 349, 4
DATA 330, 2, 349, 2, 392, 2, 330, 2, 294, 4, 349, 4
DATA 330, 2, 349, 2, 392, 2, 330, 2
DATA 349, 2, 392, 2, 440, 2, 494, 2
DATA 523, 4, 494, 4, 523, 4


'---- demo number four shows the ten sounds produced by Chime

FOR X = 1 TO 10                 'demo the canned chime sounds
    PRINT "Chime sound number"; X
    Chime X
    Pause 10
NEXT


'The table below shows musical pitches and their corresponding frequencies.
'This lets you construct DATA statements for use with QPSound in a manner
'similar to programming melodies with BASIC's PLAY statement.
'
'               Oct 1   Oct 2   Oct 3   Oct 4   Oct 5   Oct 6   Oct 7
'ÛÛÛÛÛÛÛÄÄÄÄ´
'         C ³     65     131     262     523    1047    2093    4186
'ÄÄÄÄÄÄÄÄÄÄÄ´
'         B ³     62     123     247     494     988    1976    3951
'ÛÛÛÛÛÛÛÄÄÄÄ´
'         A ³     55     110     220     440     880    1760    3520
'ÛÛÛÛÛÛÛÄÄÄÄ´
'         G ³     49      98     196     392     784    1568    3136
'ÛÛÛÛÛÛÛÄÄÄÄ´
'         F ³     44      87     175     349     698    1397    2794
'ÄÄÄÄÄÄÄÄÄÄÄ´
'         E ³     41      82     165     330     659    1319    2637
'ÛÛÛÛÛÛÛÄÄÄÄ´
'         D ³     37      73     147     294     587    1175    2349
'ÛÛÛÛÛÛÛÄÄÄÄ´
'         C ³     33      65     131     262     523    1047    2093
'ÄÄÄÄÄÄÄÄÄÄÄ´

