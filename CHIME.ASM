;********** Chime.Asm - assortment of chime sounds using less code than PLAY

;Copyright (c) 1989 Ethan Winer
;BC7 version

;Syntax: CALL Chime(Number%)
;
;Where Number% is a value from 1 to Max (defined below).
;
;This routine is fully table driven, which makes it very easy to expand to
;add more chime variations.  Simply increase the Max equate value below to
;whatever you want, and then add the corresponding number of entries in the
;data table at the end of this listing.  The organization of the table is
;clearly shown below, and is designed to accommodate a variable number of
;pitches and durations.  The minimum legal pitch value is 37.
;
;Notice that this table is kept in the code segment to avoid stealing any
;string memory from your BASIC program.


.Model Medium,BASIC
.Data
    Delay DW ?            ;Pause needs it's parameter here in near memory

.Code
    Extrn Pause:Proc      ;we'll use the QuickPak Professional Pause routine
    Max = 10              ;the number of different chime types

Chime Proc Uses ES SI DI, Number:Ptr

    Mov  Delay,1          ;call Pause once to insure full period on first tone
    Mov  BX,Offset Delay  ;get the address of the Pause parameter
    Push BX               ;show Pause where it is
    Call Pause            ;do it to it

    Mov  SI,Number        ;get the address for Number%
    Mov  AX,[SI]          ;put it into AX
    Or   AX,AX            ;did they slip us a zero by mistake?
    Jz   Exit             ;yup, bye bye
    Cmp  AX,Max           ;are they requesting an illegal chime number?
    Ja   Exit             ;yes, exit
    Neg  AX               ;no, make equivalent negative value for searching

    Mov  CX,(Offset TableEnd - Offset Table) / 2  ;calc how many words to scan
    Push CS               ;set ES=CS for searching
    Pop  ES
    Mov  DI,Offset Table  ;point DI to the start of the table
    Repne Scasw           ;search for the correct entry

    Mov  CX,CS:[DI]       ;get the number of notes to play
    Inc  DI               ;skip past the note count in the table to the first
    Inc  DI               ;  frequency entry (two Inc's is faster than an Add)

    Mov  AL,10110110b     ;initialize Timer 2 for sound
    Out  43h,AL

More:
    Mov  DX,12h           ;load DX:AX with 1,190,000 to convert
    Mov  AX,2870h         ;  the incoming frequency to period (1/f)
    Div  Word Ptr CS:[DI] ;now AX holds the correct interval period
    Inc  DI               ;bump past the current frequency
    Inc  DI               ;  to the Pause time entry in the table

    Out  42h,AL           ;send the interval information to Timer 2
    Mov  AL,AH            ;first the low byte in AL, then the high byte in AH
    Out  42h,AL
    In   AL,61h           ;read timer port "B"
    Or   AL,00000011b     ;set the bits to turn the speaker on
    Out  61h,AL           ;turn it on

    Mov  AX,CS:[DI]       ;now get the note duration
    Mov  Delay,AX         ;and save it where Pause can get at it
    Inc  DI               ;bump past the duration parameter
    Inc  DI               ;  to the next frequency entry in the table

    Push CX               ;save CX because Pause trashes it
    Push BX               ;send the address of Delay to Pause
    Call Pause            ;pause for Delay clock ticks
    Pop  CX               ;restore CX
    Loop More             ;loop until done

    In   AL,61h           ;read timer port "B"
    And  AL,11111100b     ;clear the bits to turn the speaker off
    Out  61h,AL           ;turn it off

Exit:
    Ret                   ;return to BASIC

Chime Endp

;The organization of the table below is a negative chime number, the total
;number of tones to play, the first frequency (in Hz.), the first duration
;(in 1/18ths of a second), the second frequency, the second duration, etc.

Table    DW  -1,  1, 100, 5     ;single tones
         DW  -2,  1, 200, 5
         DW  -3,  1, 400, 5
         DW  -4,  1, 800, 5
         DW  -5,  1, 1600, 5

         DW  -6,  4, 659, 1, 523, 1, 659, 1, 523, 1
         DW  -7, 10, 300, 1, 350, 1, 400, 1, 450, 1, 500, 1, 550, 1, 600, 1
         DW          650, 1, 700, 1, 750, 1
         DW  -8,  8, 1000, 1, 1100, 1, 1200, 1, 1300, 1, 1400, 1, 1500, 1
         DW          1600, 1, 1700, 1
         DW  -9,  6, 200, 1, 400, 1, 800, 1, 1600, 1, 3200, 1, 6400, 1
         DW -10,  7, 220, 1, 330, 1, 440, 1, 660, 1, 880, 1, 1319, 1, 1760, 1

TableEnd Label Byte

End
