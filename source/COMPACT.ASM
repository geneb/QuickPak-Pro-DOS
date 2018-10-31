;---- Compact.Asm - compacts a string by sliding all non-blank characters left

;Copyright (c) 1988 Crescent Software

;rewritten by EW 5-17-89 to honor spaces within quoted strings

;Syntax - NewString$ = Compact$(Old$)
;
;NOTE: Old$ also gets compacted in the process.  Use Compact$((Old$)) to
;      avoid that if you care.

.Model Medium
.Data
    DescrLen  DW ?          ;this is a "home-made" string descriptor
    DescrAdr  DW ?
    InQuote   DB ?          ;this tracks if we're within a quoted string

.Code
    Include Mixed.Inc

HProc Compact, Old:Ptr

    Push DS               ;assign ES = DS
    Pop  ES
    Cld                   ;all string moves will be forward

    Mov  SI,Old           ;get the address for Old$
    Mov  CX,[SI]          ;put LEN(Old$) into CX
    Mov  SI,[SI+02]       ;and the address into SI
    Mov  DescrLen,CX      ;assume the full length of Old$
    Mov  DescrAdr,SI      ;the function output starts where Old$ starts
    Mov  InQuote,0        ;zero out the InQuote flag
    Jcxz Exit             ;they gave us a null string, so return a null

MainLoop:
    Mov  DI,SI            ;have DI track where SI is before the Lodsb
    Lodsb                 ;get the next character from Old$
    Cmp  AL,34            ;is it a quote?
    Jne  NotQuote         ;no, skip ahead
    Not  InQuote

NotQuote:
    Cmp  AL,32            ;is it a blank?
    Jne  NotBlank         ;no, skip ahead
    Test AL,InQuote       ;yes, but are we within a quoted string?
    Jnz  NotBlank         ;yes, so don't do anything

    Dec  DescrLen         ;no, show the output being one character shorter
    Push SI               ;save the critical registers for a moment
    Push CX
    Dec  CX               ;we want to copy only those remaining past here
    Rep  Movsb            ;squish the string
    Pop  CX               ;retrieve the registers
    Pop  SI
    Dec  SI               ;slide SI back one to catch the next character

NotBlank:
    Loop MainLoop         ;loop until Old$ is exhausted

Exit:
    Mov  AX,Offset DescrLen  ;show BASIC where the string descriptor is
    HRet                     ;return to BASIC

HEndp
End
