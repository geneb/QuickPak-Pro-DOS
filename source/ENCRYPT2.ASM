;----- Encrypt2.Asm - similar to Encrypt, but uses a more secure algorithm

;Copyright (c) 1988 Crescent Software
; Written by Paul Passarelli


;Syntax - Call Encrypt2(X$, PassWord$)
;
;  where X$ will be encrypted using the characters in PassWord$ as a key

;NOTE:  This routine is NOT compatible with the original Encrypt program.
;       If you intend to change over to this method you MUST restore your
;       original data to its original form and then encrypt it again with
;       this routine.  Also, to save space, time, and trouble, you must
;       limit the length of the password to 44 characters or less.


.Model          Medium
.Data

     Extrn QPDTA:Byte     ;these are in External.Asm
     Extrn File_Name:Byte

.Code
Include         Mixed.Inc

HProc Encrypt2, XString:Ptr, PassWord:Ptr

      Mov  SI,PassWord    ;locate the PassWord$ descriptor
      Mov  CX,[SI]        ;get the length of the PassWord$
      Jcxz Exit           ;if it's null bag out
      Cmp  CX,44          ;compare to the length of the available buffer
      Ja   Exit           ;it's too long, bag out

      Push DS             ;set ES to match DS
      Pop  ES
      Cld                 ;so the string moves below will be forward
      Mov  SI,[SI+02]     ;make SI point to PassWord$ data
      Mov  DI,Offset QPDTA  ;make DI point to temp storage
      Mov  DX,DI          ;save pointer to QPDTA in DX
      Mov  BX,CX          ;copy length of PassWord$ to BX (BL really)
      Or   BH,BL          ;and in BH too

      Rep  Movsb          ;copy PassWord$ into local storage
      Mov  SI,DX          ;make SI point to the copy
      Mov  DI,XString     ;locate XString$
      Mov  CX,[DI]        ;measure it's length in CX
      Jcxz Exit           ;if this one is null bag out
      Mov  DI,[DI+2]      ;put the XString$ address in DI

XCode:
      Add Byte Ptr[SI],17 ;add this to the copy of PassWord$ to constantly
                          ;  change it - simple but effective
      Lodsb               ;get the current character in PassWord$
      Xor [DI],AL         ;code the XString$ byte
      Inc DI              ;point to the next XString$ byte
      Dec BL              ;we used one PassWord$ character
      Ja  XCont           ;still more to go, skip to the loop instruction
      Mov SI,DX           ;wrap to the beginning of PassWord$ to go again
      Mov BL,BH           ;restore the PassWord$ length

XCont:
      Loop XCode

Exit:
      HRet

HEndP
End
