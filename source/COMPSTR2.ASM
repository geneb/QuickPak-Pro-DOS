;************ COMPSTR.ASM

;Compares Fixed length string to variable length string
;ignores capitalization
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

Comp_Str2 Proc Uses SI

    Push BX                  ;preserve registers
    Push CX
    Push DX

    Mov  CS:ElSize,BX         ;save fixed length string size
    Mov  CX,[SI]              ;get length and address of string
    Mov  CS:Search_Len,CX     ;save for later
    Mov  SI,[SI+2]            ;address of search$
    Mov  DX,BX                ;DX keeps track of previous position in Array$
                              ;  in case of a false partial match

    Push SI                   ;save SI while we capitalize it

CapSearch:
    Mov  AL,[SI]              ;get the current character in Search$
    Cmp  AL,"a"               ;lower than "a"
    Jb   NoCap                ;no, skip ahead
    Cmp  AL,"z"               ;higher than "z"
    Ja   NoCap                ;yes, skip
    And  AL,95                ;clear the lower case bit
    Mov  [SI],AL              ;put the character back into the string

NoCap:
    Inc  SI                   ;point to the next character in Search$
    Loop CapSearch            ;loop until done
    Pop  SI                   ;all done, get SI back again

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

    Cmp  AL,"a"       ;lower than "a"?
    JB   No_Cap       ;yes, skip it
    Cmp  AL,"z"       ;higher than "z"?
    JA   No_Cap       ;yes, skip it
    And  AL,95        ;convert to upper case

No_Cap:
    Cmp  AL,[BP+SI]        ;a match?
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

Comp_Str2 Endp

    Search_Len DW ?           ;storage for Len(Search$)
    ElSize     DW ?           ;for ElSize%


End
