;----- EuroSwap.Asm - swaps digits around, used by the European date routines

;Copyright (c) 1989 Ethan Winer


.Model Medium
.Code
Include Mixed.Inc

HProc EuroSwap            ;routine to swap the day and month digits
                          ;enter with DI pointing to start of the date string

    Mov  SI,DI            ;point SI to the beginning of the American date
    Add  SI,2             ;now SI points to the second digit pair
    Mov  BL,[SI]          ;but it might be a delimiter, get it to see
    Sub  BL,"0"           ;if it's a delimiter, this'll bump it to below zero
    Jns  Exchange         ;it's not signed so it must be a digit, go swap 'em
    Inc  SI               ;skip over the delimiter

Exchange:
    Mov  BX,[DI]          ;get the leading digit pair
    Xchg BX,[SI]          ;swap it with the second digit pair
    Xchg BX,[DI]          ;and swap the second pair with the first
    HRet                  ;return to caller (EDate2Num or ENum2Date)

HEndp
End
