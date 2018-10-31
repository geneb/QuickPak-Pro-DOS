;********** Delete.Asm - "deletes" an element from a string array

;Copyright (c) 1988 Ethan Winer


;Syntax - CALL DeleteStr(BYVAL VARPTR(Array$(Start)), Size%)
;
;   Where Array$(Start) is the element to be deleted, and Size% is the
;   number of elements that follow.  Notice that the deleted string ends
;   up in the last element of the array.
;
;   The equivalent BASIC algorithm is:
;
;      FOR X = Start TO (Start + Size%)
;          SWAP Array$(X), Array$(X + 1)
;      NEXT


.Model Medium
.Code

Include Mixed.Inc

HProc DeleteStr, Array:Ptr, Siz:Ptr

    Mov  SI,Siz           ;get the address for Size%
    Mov  CX,[SI]          ;put the number of elements into CX
    Cmp  CX,1             ;is it zero or - gasp! - a negative value?
    Jl   Exit             ;yes, go away

    Mov  SI,Array         ;get the address for Array$(Start)
    Mov  DI,SI            ;point DI to the same descriptor SI points to
    Add  DI,4             ;now DI points to the element beyond the one
                          ;  pointed to by SI
More:
    Call Do_Swap          ;swap 'em
    Add  SI,4             ;point SI and DI to the next elements
    Add  DI,4
    Loop More             ;loop until done
    Jmp  Short Exit       ;all done



Do_Swap    Proc Near      ;enter with SI pointing to descriptor #1,
                          ;  and DI pointing to descriptor #2
                          ;  destroys AX, BX, CX, and BP

    Cmp  Word Ptr [SI],0  ;check LEN(Array$(SI)) - is it zero?
    Jz   SI_Null          ;yes, do special back-pointer exchange
    Cmp  Word Ptr [DI],0  ;check LEN(Array$(DI)) - is it zero?
    Jnz  Full_Swap        ;no, do full swap including back-pointers,
                          ;  length, and address words
    Xchg SI,DI            ;exchange SI & DI - it's easier if the null
                          ;  string is always in the same place
SI_Null:
    Cmp  Word Ptr [DI],0  ;is Array$(DI) null too?
    Jz   Exit_Swap        ;yes, don't bother
;   Mov  BX,[SI+2]        ;get address of Array$(SI)'s string data
;   Mov  [BX-2],BX        ;and put it into Array$(DI)'s future back-pointer
    Mov  BX,[DI+2]        ;get address of Array$(DI)'s string data
    Mov  [BX-2],SI        ;put Array$(SI)'s VARPTR address into Array$(SI)'s
                          ;  future back-pointer
    Jmp  Short LA_Swap    ;back-pointers are now correct, skip over the
                          ;back-pointer swap and just swap length & address
Full_Swap:
    Mov  BX,[SI+2]        ;get address of Array$(SI) back-pointer + 2
    Mov  AX,[BX-2]        ;save Array$(SI) back-pointer in AX
    Mov  BP,[DI+2]        ;get address of Array$(DI) back-pointer + 2
    Mov  DX,[BP-2]        ;save Array$(DI) back-pointer in CX
    Mov  [BP-2],AX        ;swap them now
    Mov  [BX-2],DX

LA_Swap:
    Mov  AX,[SI]          ;get length word of Array$(SI)
    Mov  BX,[DI]          ;and length word of Array$(DI)
    Mov  [DI],AX          ;swap them
    Mov  [SI],BX

    Mov  AX,[SI+2]        ;get word pointing to Array$(SI)
    Mov  BX,[DI+2]        ;and word pointing to Array$(DI)
    Mov  [DI+2],AX        ;swap them
    Mov  [SI+2],BX

Exit_Swap:
    Ret

Do_Swap    Endp

Exit:
    HRet

HEndp
End
