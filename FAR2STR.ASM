;********* FAR2STR.ASM - returns a far ASCIIZ string as a normal BASIC string

;Copyright (c) 1990 Ethan Winer


;to make the PDS version assemble with MASM 5.1 like this: MASM SPELL /DPDS;

.Model Medium,BASIC
;Syntax:  Work$ = Far2Str$(BYVAL LongInt&)

IFDEF PDS
   Extrn StringAssign:  Proc
ENDIF

.Data
    Descriptor DW 0, Offset Output  ;this is the output string descriptor
    Output DB 40 Dup (?)            ;this is the returned string data

IFDEF PDS
   PDSDescriptor DD 0
ENDIF
    
.Code

Far2Str Proc Uses ES SI DI, LongAddress:DWord

    Xor  AX,AX                  ;make a zero (this actually saves a byte)
    Mov  Descriptor,AX          ;initialize the output length to zero

    Cld                         ;so string ops will be forward
    Push DS                     ;copy DS to ES
    Pop  ES
    Push DS                     ;save DS before we trash it

    Lds  SI,LongAddress         ;point DS:SI to the far string
    Mov  DI,Offset Output       ;point ES:DI to the near output data
    Mov  CX,40                  ;ensure that no more than 40 bytes are copied

Copy:
    Lodsb                       ;load a byte from memory
    Or   AL,AL                  ;is it the zero that marks the end?
    Jz   Done                   ;yes, we're all done here
    Stosb                       ;no, copy the byte to local storage
    Inc  SS:Descriptor          ;and show the output being that much longer
    Loop Copy                   ;loop until done

Done:
    Pop  DS                     ;restore DS

IFDEF PDS                       ;if its for PDS then use this code
    Mov  BX,Offset Descriptor   ;do it from the descriptor
    Push DS                     ;segment of string
    Mov  AX,Offset Output       ;offset of string data
    Push AX                     ;push it
    Push Word Ptr [BX]          ;length of string [descriptor]
    Push DS                     ;segment of descriptor
    Mov  AX,Offset PDSDescriptor ;special PDS descriptor (non-trashable)
    Push AX                     ;offset of descriptor
    Xor  AX,AX                  ;zero means variable length string
    Push AX
    Call StringAssign           ;do it!
    
ELSE
    Mov  AX,Offset Descriptor   ;show where the output string descriptor is
ENDIF

    Ret                         ;return to BASIC

Far2Str Endp
End
