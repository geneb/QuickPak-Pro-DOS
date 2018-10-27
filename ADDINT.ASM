;----- AddInt.Asm - adds an integer constant to an entire integer array

;Copyright (c) 1989 Ethan Winer
;BC7 version
;Syntax - CALL AddInt(SEG Array%(Start), Value%, Size%)
;
;where Size% elements will have Value% added starting at element Start

.Model Medium,BASIC
.Code


AddInt Proc  Uses ES DS SI, ArrayAdr:DWord, Value:Ptr, Siz:Ptr

    Mov  SI,Siz            ;get the number of bytes to fill
    Mov  CX,[SI]           ;put it into CX
    Jcxz Exit              ;no Size% - somebody goofed, get out now
    Cld                    ;insure that SI and DI are incremented

    Mov  SI,Value          ;get the pointer to Value%
    Mov  BX,[SI]           ;put Value% into BX

    Lds  SI,ArrayAdr       ;get the segment and offset for the array
    Push DS                ;put the same segment into ES
    Pop  ES
    Mov  DI,SI             ;copy the address from SI into DI

Do_Add:
    Lodsw                  ;get the current array element
    Add  AX,BX             ;add Value%
    Stosw                  ;put it back into the array
    Loop Do_Add            ;loop until done

Exit:
    Ret

AddInt Endp
End
