;----- Encrypt.Asm - encrypts/decrypts a string using a password

;Copyright (c) 1987 Ethan Winer

;Syntax - Call Encrypt(X$, PassWord$)
;
;  where X$ will be encrypted using the characters in PassWord$ as a key


.Model          Medium
.Code
Include         Mixed.Inc

HProc Encrypt, XString:Ptr, PassWord:Ptr

    Mov  BX,DS              ;set ES to DS to use Stosw below
    Mov  ES,BX

    Mov  BX,XString         ;get X$ descriptor address
    Mov  CX,[BX]            ;get its length
    Jcxz Exit               ;can't encrypt a null string, exit
    Mov  DI,[BX+02]         ;now DI points to X$ data

    Mov  BX,PassWord        ;get password descriptor address
    Mov  DX,[BX]            ;put LEN(PassWord$) into DX
    Cmp  DX,0               ;see if it's a null string
    Jz   Exit               ;yes, exit
    Dec  DX                 ;adjust so 0 equals length of 1
    Mov  SI,[BX+02]         ;now SI points to PassWord$ data
    Mov  BX,DX              ;BX will be an index into PassWord$

More:
    Inc  BX                 ;point to next character in PassWord$
    Cmp  BX,DX              ;are we past the end?
    Jna  Okay               ;no, okay to continue
    Mov  BX,0               ;yes, wrap to the start of PassWord$

Okay:
    Mov  AL,[DI]            ;get a character from X$
    Xor  AL,[SI+BX]         ;encrypt it
    Stosb                   ;put it into X$, increment X$ pointer
    Loop More               ;no, continue

Exit:
    HRet

HEndP
End
