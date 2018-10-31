;********* Compare.Asm - compares two blocks of memory

;Copyright (c) 1988 Ethan Winer
;BC7 conversion JM '89

;Syntax -
;
;   X = Compare%(Seg1%, Addr1%, Seg2%, Addr2%, NumBytes%)
;
;where NumBytes% starting at Seg1% and Addr1% are compared against the
;same number of bytes at Seg2% and Addr2% - the function returns -1 if
;the memory blocks are the same, or 0 if they are different
;
;NOTE: NumBytes% may also be coded as in the various sort routines:
;
;   -1    2-byte integer
;   -2    4-byte long integer     } these are
;   -3    4-byte single precision } the same
;   -4    8-byte double precision
;   -5    8-byte currency
;   +n    n-byte fixed-length string or any data


.Model Medium,BASIC
.Code

    Extrn Code2Num: Proc

Compare Proc Uses ES SI DI, Seg1:Ptr, Adr1:Ptr, Seg2:Ptr, Adr2:Ptr, NumBytes:Ptr

    Cld                   ;compare in the forward direction
    Mov  DX,DS            ;save DS in DX (faster than pushing and popping)

    Mov  BX,Adr1          ;get pointer to Addr1%
    Mov  DI,[BX]          ;put into SI
    Mov  BX,Seg1          ;pointer to Seg1%
    Mov  ES,[BX]          ;put it into ES

    Mov  BX,Adr2          ;pointer to Addr2%
    Mov  SI,[BX]          ;put it into DI
    Mov  BX,NumBytes      ;pointer to NumBytes%
    Mov  CX,[BX]          ;put it into CX
    Mov  BX,Seg2          ;pointer to Seg2%
    Mov  DS,[BX]          ;put Seg2 into DS

    Call Code2Num         ;convert possible negative code to number of bytes
    Repe Cmpsb            ;do the compare

    Mov  AX,-1            ;assume all the bytes matched
    Je   Exit             ;we were right, skip over
    Inc  AX               ;wrong RAM breath, increment AX up to zero

Exit:
    Mov  DS,DX            ;restore DS
    Ret                   ;return to BASIC

Compare Endp
End
