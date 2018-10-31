;********** DeleteT.Asm - deletes an element from a numeric or TYPE array

;Copyright (c) 1988 Ethan Winer


;Syntax - CALL DeleteT(SEG StartElement, ElSize%, NumEls%)
;
;   Where StartElement is the array position where the element to be
;   deleted is located, ElSize% is either a type code or the length
;   in bytes of one record, and NumEls% is the total number of elements
;   to be shifted downward (the number of elements beyond StartElement).
;   Notice that the last element in the array is not erased or removed.
;
;   The code for ElSize% is as follows:
;
;       -1 = 2-byte integer
;       -2 = 4-byte long integer or single precision}  <--- these two are
;       -3 = 4-byte long integer or single precision}  <--- interchangeable
;       -4 = 8-byte double precision
;       -5 = 8-byte currency
;       +n = n-byte TYPE variable
;
;   The equivalent BASIC algorithm is:
;
;      FOR X = StartElement TO StartElement + NumEls - 1
;          Array(X) = Array(X + 1)
;      NEXT


.Model Medium,BASIC
.Code

    Extrn Code2Num: Far

DeleteT Proc Uses DS ES SI DI, AAdr:DWord, ElSize:Ptr, NumEls:Ptr

    Cld                   ;all memory moves will be stepping forward
    Mov  SI,NumEls        ;get the address for NumEls%
    Mov  AX,[SI]          ;put NumEls% into AX
    Or   AX,AX            ;did they specify zero elements?
    Jz   Exit             ;yes, go to bed without supper

    Mov  SI,ElSize        ;get the address for ElSize%
    Mov  CX,[SI]          ;put ElSize% into CX
    Call Code2Num         ;convert possible size code to number of bytes
    Jcxz Exit             ;we can't delete a zero-length element!

    Mul  CX               ;multiply to find how many bytes are to be moved
                          ;  the answer ends up in DX:AX
    Les  DI,AAdr          ;load ES:DI with segment/address for StartElement
    Or   DI,DI            ;is this address beyond a 32K boundary?
    Jns  NoSpan1          ;no, don't adjust address and segment
    And  DI,7FFFh         ;yes, subtract 32K from the address
    Mov  BX,ES            ;add 800h to the segment to compensate
    Add  BX,800h
    Mov  ES,BX

NoSpan1:
    Push ES               ;point DS:SI to the next element after StartElement
    Pop  DS
    Mov  SI,DI
    Add  SI,CX            ;add ElSize% (still held in CX)

MoveLoop:
    Or   SI,SI            ;is this address beyond a 32K boundary?
    Jns  NoSpan2          ;no, don't adjust the address and segment
    And  SI,7FFFh         ;yes, subtract 32K from the address
    Mov  BX,DS            ;add 800h to the segment
    Add  BX,800h
    Mov  DS,BX

NoSpan2:
    Or   DI,DI            ;is this address beyond a 32K boundary?
    Jns  NoSpan3          ;no, don't adjust the address and segment
    And  DI,7FFFh         ;yes, subtract 32K from the address
    Mov  BX,ES            ;add 800h to the segment
    Add  BX,800h
    Mov  ES,BX

NoSpan3:
    Or   DX,DX            ;see if there's at least 64K bytes left to move
    Jnz  BigMove          ;yes, move a 32K block
    Or   AX,AX            ;see if there's at least 32K left
    Js   BigMove          ;yes

    Mov  CX,AX            ;less than 32K left, put bytes remaining into CX
    Rep  Movsb            ;move 'em good
    Jmp  Short Exit       ;and go bye bye

BigMove:
    Mov  CX,8000h         ;specify moving 32K bytes
    Sub  AX,CX            ;and subtract 32K bytes from the amount remaining
    Sbb  DX,0             ;adjust DX if needed
    Rep  Movsb            ;do the move
    Jmp  Short MoveLoop   ;and go get some more

Exit:
    Ret                   ;return to BASIC

DeleteT Endp
End
