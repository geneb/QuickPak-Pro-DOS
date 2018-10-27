;************ COMPSTR.ASM

;Compares a fixed-length string to a variable length string
;honors capitalization
;Copyright 1990 Crescent Software
;modified from FindT by Jay Munro
;QB4 version

;======================================================================
;  COMP_Str - Compare Variable length string to fixed length string

;
;  On entry:
;       DS:SI   = pointer to first string descriptor
;       ES:DI   = pointer to second string (fixed length)
;       BX      = length of fixed length string
;
;  On exit:
;       AX = -1 for match, 0 for no match
;       All registers preserved

.Model Medium,BASIC
.Code

Comp_Str Proc Uses SI

    Push BX                  ;preserve registers
    Push CX
    Push DX

    Mov  CS:ElSize,BX         ;save fixed length string size
    Mov  CX,[SI]              ;get length and address of string
    Mov  CS:Search_Len,CX     ;save for later
    Mov  SI,[SI+2]            ;address of search$
    Mov  DX,BX                ;DX keeps track of previous position in Array$
                              ;  in case of a false partial match
Try_Again:
    Mov  BP,CS:Search_Len     ;put LEN(Search$) into BP for indexing
    Cmp  DX,BP                ;enough characters to justify continuing?
    Jb   Next_Element         ;no, go on to the next element
    Dec  DX                   ;have DX follow changes in BX below

Maybe:
    Dec  BP                   ;point to previous character in search string
    Js   Found                ;if searching held out this far, we've got one!
    Dec  BX                   ;consider previous character in Array$
    Js   Next_Element         ;no more, go on to next element
    Cmp  Byte Ptr [BP+SI],"?" ;is it the wildcard?
    Jz   Maybe                ;yes, keep checking
    Mov  AL,ES:[BX+DI]        ;get current character in Array$

    Cmp  AL,[BP+SI]           ;a match?
    Jz   Maybe                ;yes, keep checking
    Mov  BX,DX                ;no - reset BX to one character before the
                              ;  beginning of the last try,
    Jmp  Short Try_Again      ;  and resume searching

Next_Element:
    Xor  AX,AX                ;set AX to show no match
    Inc  AH                   ;
    Cmp  AH,AL                ;for ne flag
    Jmp  Short Not_Found

Found:
    Cmp  AL,AL                ;found it

Not_Found:
    Pop  DX
    Pop  CX
    Pop  BX
    Ret                       ;return to BASIC

Comp_Str Endp

    Search_Len DW ?           ;storage for Len(Search$)
    ElSize     DW ?           ;for ElSize%


End
