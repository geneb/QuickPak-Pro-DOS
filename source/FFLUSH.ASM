;----- FFlush.Asm - flushes a file's buffer to disk without having to close it

;Copyright (c) 1988 Ethan Winer
;Revised Jan 89 - J. R. Conrad

;calling Syntax - CALL FFlush(Handle%)
;
;This program works by asking DOS to create a duplicate file handle, and
;then closing that duplicate handle.  This causes the original file's
;buffers to be flushed to disk, and its directory entry to be updated too.
;Errors are returned in DOS/WhichError.
;
;NOTE: This routine is intended for use with the QuickPak Professional
;      Binary file routines only.  QuickBASIC performs additional file
;      buffering behind DOS' back, rendering this technique useless with
;      normal BASIC file commands.


.Model Medium, Basic

.Code
    Extrn Setup_CEH:Far, Restore_CEH:Far, Load_DOSErr:Far, DOS:Far

FFlush Proc Uses SI, Handle:Ptr

    Mov  DX,CS            ;install CEH
    Lea  BX,CS:Exit
    Call Setup_CEH

    Mov  SI,Handle        ;get the address for Handle%
    Mov  BX,[SI]          ;put the handle number into BX

    Mov  AH,45h           ;service to duplicate a file handle
    Call DOS              ;call DOS to do it
    Jc   Error            ;DOS says an error occurred

    Mov  BX,AX            ;put the new handle into BX
    Mov  AH,3Eh           ;and close the "alias" file
    Call DOS              ;call DOS to do it
    Jnc  Exit             ;if not carry, then exit

Error:
    Call Load_DOSErr

Exit:
    Call Restore_CEH
    Ret                   ;return to BASIC

FFlush Endp
End
