;----- Empty.Asm - empty procedure for benchmarking

;Copyright (c) 1989 Ethan Winer

;Syntax - CALL Empty(AnyVariable)
;
;This procedure is useful when timing QuickBASIC operations.  For example,
;to test if MID$ is faster than LEFT$, you'd need to do something with these
;functions that took as little time as possible.  Consider this test code:
;
;    FOR X = 1 TO 1000
;        PRINT MID$(Work$, 1, 10)
;    NEXT
;
;Here, the time needed for BASIC to process the MID$ argument will be
;hopelessly skewed by the overhead of PRINT.  Likewise, using an assignment
;would be influenced by how long it takes to allocate memory.  Instead use:
;
;    FOR X = 1 TO 1000
;        CALL Empty(MID$(Work$, 1, 10))
;    NEXT
;
;Then you could compare it to:
;
;    FOR X = 1 TO 1000
;        CALL Empty(LEFT$(Work$, 10))
;    NEXT
;
;Of course, you'd also use TIMER before and after the loop.


.Model Medium
.Code

Public Empty

Empty Proc Far

    Ret  2

Empty Endp
End
