;********* BCopyT.Asm - like BCopy, but optimized for use with TYPE variables

;Copyright (c) 1989 Ethan Winer
;BC7 version

;Syntax -
;
;   CALL BCopyT(SEG FromEl AS ANY, SEG ToEl AS ANY, ElSize%, NumEls%)
;or
;   CALL BCopyT(BYVAL FromSeg%, BYVAL FromAdr%, BYVAL ToSeg%, BYVAL ToAdr%, _
;               ElSize%, NumEls%)
;
;ElSize% may also be coded using the QuickPak Professional TYPE sort codes.

.Model Medium,BASIC
.Code

    Extrn Code2Num: Proc

BCopyT Proc Uses DS ES SI DI, FromEl:DWord, ToEl:DWord, ElSize:Ptr, NumEls:Ptr

    Mov  SI,ElSize         ;get the address for ElSize%
    Mov  CX,[SI]           ;put it into CX for Code2Num
    Call Code2Num          ;convert possible size code to number of bytes
    Jcxz Exit              ;zero length specified, get out
    Mov  DX,CX             ;save ElSize% in DX for later

    Mov  SI,NumEls         ;get the address for NumEls%
    Mov  CX,[SI]           ;put it in CX for the Loop counter below
    Jcxz Exit              ;zero elements specified, get out

    Les  DI,ToEl           ;load ES:DI with the destination segment:address
    Lds  SI,FromEl         ;load DS:SI with the source segment:address
    Cld                    ;ensure that string moves are forward

DoCopy:
    Or   SI,SI             ;is SI beyond a 32K boundary?
    Jns  NS1               ;no, skip ahead
    And  SI,7FFFh          ;yes, subtract 32K from the address
    Mov  AX,DS             ;and add an appropriate amount to the segment
    Add  AX,800h           ;  to compensate
    Mov  DS,AX             ;  through AX

NS1:
    Or   DI,DI             ;is DI beyond a 32K boundary?
    Jns  NS2               ;no, skip ahead
    And  DI,7FFFh          ;yes, subtract 32K from the address
    Mov  AX,ES             ;and add an appropriate amount to the segment
    Add  AX,800h           ;  to compensate
    Mov  ES,AX             ;  through AX

NS2:
    Mov  BX,CX             ;save NumEls% (now held in CX) to BX for a moment
    Mov  CX,DX             ;load CX with ElSize% (number of bytes to copy)
    Rep  Movsb             ;copy the current element
    Mov  CX,BX             ;get NumEls% back again
    Loop DoCopy            ;loop until done

Exit:
    Ret                    ;return to BASIC

BCopyT Endp
End
