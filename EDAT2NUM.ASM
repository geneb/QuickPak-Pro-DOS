;----- EDat2Num.Asm - calls Date2Num, provides a front-end for European dates

;Copyright (c) 1988 Ethan Winer

;Syntax - Dat$ = "DDMMYY" (or "DDMMYYYY" or DD/MM/YY or DD-MM-YYYY or . . .)
;         Number = EDate2Num%(Dat$)
;
;where Number receives the number of days before/after 31-Dec-1979
;if Dat$ is illegal, Number instead receives -32768

.Model Medium, Basic
    Extrn Date2Num: Proc  ;we'll let Date2Num do the real work
    Extrn EuroSwap: Proc  ;this is in EUROSWAP.ASM

.Data
    Buffer DW 0, 0        ;this holds the string descriptor
    Buf2   DB 10 Dup (0)  ;and this holds the new date

.Code

EDate2Num Proc Uses SI DI, Date:Word

    Mov  SI,Date          ;get the descriptor address for Dat$
    Mov  AX,-32768        ;assume the string is invalid
    
    Mov  CX,[SI]          ;first get LEN(Dat$)
    Jcxz Exit             ;it's null, bag out
    Cmp  CX,10            ;now see if it's too long
    Ja   Exit             ;yup, and that's no good either
    
    Mov  SI,[SI+02]       ;now SI points to the characters in Dat$
    Push DS               ;assign ES=DS for Movsb below
    Pop  ES
    Cld                   ;assure that string moves are forward

    ;---- build a string descriptor in Buffer and copy the date there
    Mov  DI,Offset Buffer ;put the address of Buffer into DI
    Push DI               ;pass the address to Date2Num in advance
    Mov  AX,CX            ;assign the length portion of the descriptor
    Stosw
    Mov  AX,Offset Buf2   ;get the address of the data
    Stosw                 ;and assign that as well
    Rep  Movsb            ;copy the date into local storage

    Mov  DI,AX            ;reset DI to point to the beginning of the string
    Call EuroSwap         ;swap the month and day digits to European format
    Call Date2Num         ;Date2Num returns the number in AX as a function

Exit:
    Ret                   ;return to BASIC with the answer still in AX

EDate2Num Endp
End
