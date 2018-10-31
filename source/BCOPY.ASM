;********* BCopy.Asm - copies a block of memory from here to there

;Copyright (c) 1989 Ethan Winer
;BC7 version

;Syntax -
;
;   CALL BCopy(FromSeg%, FromAddr%, ToSeg%, ToAddr%, NumBytes%, Direction%)

;Where Direction% = 0 for forward, or anything else for backwards


.Model Medium,BASIC
.Code

BCopy Proc Uses DS ES SI DI, FromSeg:Ptr, FromAdr:Ptr, ToSeg:Ptr, ToAdr:Ptr, NumBytes:Ptr, Dir:Ptr

    Cld                    ;assume forward direction for now
    Mov  BX,Dir            ;get pointer to Direction%
    Cmp  Word Ptr [BX],0   ;is it indeed forward?
    Je   Continue          ;yes, skip over
    Std                    ;no, set the flag to backwards

Continue:
    Mov  BX,FromAdr        ;get pointer to FromAddr%
    Mov  SI,[BX]           ;put into SI
    Mov  BX,ToSeg          ;pointer to ToSeg%
    Mov  ES,[BX]           ;put it into ES
    Mov  BX,ToAdr          ;pointer to ToAddr%
    Mov  DI,[BX]           ;put it into DI
    Mov  BX,NumBytes       ;pointer to NumBytes%
    Mov  CX,[BX]           ;put it into CX
    Mov  BX,FromSeg        ;pointer to FromSeg%

    Push DS                ;save DS because it'll get trashed next
    Mov  DS,[BX]           ;put segment in DS
    Rep  Movsb             ;do the move: [DS:SI] ---> [ES:DI]
    Pop  DS                ;restore DS

    Cld                    ;a bug in QB 4.0 requires this
    Ret                    ;return to BASIC

BCopy Endp
End
