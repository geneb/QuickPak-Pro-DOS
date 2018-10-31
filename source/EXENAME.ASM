;********* ExeName.Asm - returns full name/path of currently executing program

;Copyright (c) 1988 Ethan Winer


;syntax -  DECLARE FUNCTION ExeName$()
;          FullName$ = ExeName$

.Model Medium, Basic
.Data
     DescrLength DW ?
     DescrAddr   DW ?
     Output DB 80 Dup(?)

.Code

ExeName Proc Uses DS

     Mov  DescrLength,0   ;assume a zero length in case we're running DOS 2
     Mov  AH,30h          ;see what version of DOS this is
     Int  21h
     Sub  AL,3            ;is it DOS 3 or later?
     Js   Exit            ;no, bail out

     Mov  AH,62h          ;ask DOS for the Program Segment Prefix's segment
     Int  21h
     Mov  ES,BX           ;put it in ES so we can get at the PSP
     Mov  ES,ES:[2Ch]     ;now put the environment's segment into ES

     Xor  DI,DI           ;search the environment starting at the beginning
     Mov  CX,65535        ;search up to 64K bytes
     Xor  AL,AL           ;search for the zero byte that ends each variable
     Cld                  ;search forward

More:
     Repne Scasb          ;do the search
     Scasb                ;was this the last environment variable?
     Jnz  More            ;no, keep searching
     Inc  DI              ;bump past the length word to the start of the name
     Inc  DI

     Mov  SI,DI           ;prepare to copy the name into local storage
     Mov  DI,Offset Output
     Mov  DescrAddr,DI    ;set up the address while we've got it in DI
     Push ES              ;swap ES and DS to copy from DS:SI to ES:DI
     Push DS
     Pop  ES
     Pop  DS

     Mov  BX,Offset DescrLength ;this fixes a MASM bug--Inc below SHOULD work

Copy:
     Lodsb                ;get a character from the EXE name
     Or   AL,AL           ;is this the zero end marker?
     Jz   Exit            ;yes, we're all done
     Stosb                ;no, copy the character into local storage
     Inc  Word Ptr ES:[BX];then show the string as being one longer
;    Inc  ES:DescrLength  ;this should work but it doesn't
     Jmp  Short Copy      ;and go back and get another character

Exit:
     Mov  AX,Offset DescrLength  ;show where our "home made" descriptor is
     Ret                         ;return to BASIC

ExeName Endp
End
