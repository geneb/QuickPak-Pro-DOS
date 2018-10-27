              Name    Clock24
              Page    ,132
              Public  Clock24
              Title   Clock24.Asm --- by Robert J. Karp


; 05/27/92  .001 PP Added code to re-synch @ 1 minute intervals.
; 06/15/92  .002 PP Changed re-synch to 5 second intervals.  Removed .001
; 07/30/92  .003 EW Altered code at label INT1C: & Moved STI
; 09/28/92  .004 PP Re-Merged files.
; 03/11/93  .005 PP

;Syntax:      CALL Clock24( row%, column%, color%, mode% )
;             Ranges:     1-25,    1-70,  0-255,   0-1

Code          Segment Byte Public 'Code'
              Assume  CS:Code, DS:Code

;----------------------------------------------------------------------------
;Data area
;----------------------------------------------------------------------------

Adapter       DB 0                          ;1 = MDA, 2 = CGA, 3 = EGA
Attribute     DB ?                          ;Requested color
Clock_Text    DB ?,?,58,?,?,58,?,?          ;HH:MM:SS am (or pm)
Counter       DB ?                          ;0 when time for update
Old_INT1C     DW ?,?                        ;Storage for old INT1C vector
Status        DB 0                          ;0 = Off, 1 = On
Video_Buffer  DW ?                          ;0B00h or 0B800h
Video_Offset  DW ?                          ;Location for screen display
FiveSec       DB 6
Interval375   DW 375

Time          STRUC
              Hrs     DB ?                  ;Storage for hours,
              Min     DB ?                  ;minutes and
              Sec     DB ?                  ;seconds
Time          ENDS

Current_Time  Time    <>                    ;DB 3 dup(?)

;----------------------------------------------------------------------------
;Execution comes here when program is CALLed from within BASIC.
;----------------------------------------------------------------------------

Clock24       Proc    Far

Begin:        PUSH    BP                    ;Save BP for BASIC
              MOV     BP,SP                 ;Get stack address
              PUSH    DS                    ;Save BASIC's data segment
              Push    SI
              Push    DI
              Push    ES
              MOV     SI,[BP+12]            ;Put row% into DH
              MOV     DH,[SI]
              DEC     DH                    ;Adjust 1-25 to 0-24
              MOV     SI,[BP+10]            ;Put column% into DL
              MOV     DL,[SI]
              DEC     DL                    ;Adjust 1-70 to 0-69
              MOV     SI,[BP+08]            ;Put color% into BL
              MOV     BL,[SI]
              MOV     SI,[BP+06]            ;Put mode% into BH
              MOV     BH,[SI]

              PUSH    CS                    ;Set DS to the code segment
              POP     DS                    ;so we can find our data

              CMP     BH,0                  ;Termination requested?
              JE      Terminate             ;Yes, restore INT 1Ch address
              CMP     BH,1                  ;Installation requested?
              JNE     Exit                  ;No, exit now

;Initialize our internal variables. Then get and display the current time.

              CALL    Initialize24

              MOV     AH,2Ch                ;Get the current time
              INT     21h                   ;Call DOS to do it
              MOV     Current_Time.Hrs,CH   ;Save hours
              MOV     Current_Time.Min,CL   ;Save minutes
              MOV     Current_Time.Sec,DH   ;Save seconds

              MOV     Counter,1             ;Always display time at start-up
              CALL    Do_Clock24            ;Display the current time

;Check to see if we're already installed. If not, save the ROM interrupt 1Ch
;vector and replace it with one pointing to our code.

              CMP     Status,1              ;Are we installed?
              JE      Exit                  ;Yes, exit now
              MOV     AX,351Ch              ;Get current interrupt 1Ch vector
              INT     21h                   ;Call DOS to do it
              MOV     Old_INT1C,BX          ;Save vector offset
              MOV     Old_INT1C[2],ES       ;Save vector segment

              MOV     AX,251Ch              ;Set new interrupt 1Ch vector
              LEA     DX,INT1C              ;Point it to our code
              INT     21h                   ;Call DOS to do it
              MOV     Status,1              ;Indicate we're on now
              JMP     SHORT Exit            ;Return to BASIC

;Execution jumps here on CALL from BASIC with mode%=0.

Terminate:    CMP     Status,1              ;Are we installed?
              JNE     Exit                  ;No, exit now
              MOV     Status,0              ;Indicate we're turning off
                                            ;Put ROM int 1C vector into DS:DX
              LDS     DX,DWORD PTR Old_INT1C
              MOV     AX,251Ch              ;Reset interrupt 1Ch vector
              INT     21h                   ;Call DOS to do it

;----------------------------------------------------------------------------
;Program exit is achieved here when CALLed from within BASIC.
;----------------------------------------------------------------------------

Exit:
              Pop     ES
              Pop     DI
              Pop     SI
              POP     DS                    ;Restore BASIC's data segment

              POP     BP                    ;Restore BP for BASIC
              RET     8                     ;Return to BASIC discarding parms
Clock24       Endp

;----------------------------------------------------------------------------
;Once installed, execution comes here with each interrupt 1Ch.
;----------------------------------------------------------------------------

INT1C:        CALL    Do_Clock24               ;Update clock if it's time
              JMP     CS:DWORD PTR Old_INT1C   ;chain to any other handlers
             ;IRET                             ;Return to interrupted program

;----------------------------------------------------------------------------
;DO_CLOCK increments Current_Time by 1 second once every 18 times it is
;called. The new time is sent to the display.
;----------------------------------------------------------------------------

Do_Clock24    Proc    Near
              PUSH    AX                    ;Save all registers we use
              PUSH    CX
              PUSH    DX
              PUSH    SI
              PUSH    DI
              PUSH    DS
              PUSH    ES

              PUSH    CS                    ;Set DS to the code segment
              POP     DS                    ;so we can find our data
              STI                           ;Allow further interrupts
              DEC     Counter               ;Show we're here
              JZ      @F
              JMP     Done                  ;If not to zero, exit
@@:
;----------------------------------------------------------------------
;Code Added 06/15/92 to re-synch @ 5 second intervals.
;----------------------------------------------------------------------
    Dec     FiveSec
    Jg      T18         ;this stays an 18 tick second (5 - 1)
    Jl      T91

    Inc     Counter     ;go for a 91'st tick
    Jmp     Done        ;we have done in 90 ticks what should have taken 91

 T91:
    Mov     FiveSec,5
 T18:
    Dec     Interval375
    Jg      T375        ;this stays an 18 tick second (5 - 1)
    Jl      T376

    Inc     Counter     ;go for a 91'st tick
    Jmp     Done        ;we have done in 90 ticks what should have taken 91

 T376:
    Mov     Interval375,375
 T375:
;----------------------------------------------------------------------

              MOV     CL,60                 ;Constant divisor
              MOV     DX,0C0Ah              ;Constant divisors
              LEA     DI,Clock_Text[6]      ;Do seconds first

              MOV     AL,Current_Time.Sec   ;Seconds in AL
              INC     AL                    ;Add 1 second
              CBW                           ;Byte to word in AX
              DIV     CL                    ;Divide seconds by 60
              MOV     Current_Time.Sec,AH   ;Save seconds
              CALL    Bin_to_ASCII24        ;Write seconds to Clock_Text

              MOV     AL,Current_Time.Min   ;Minutes in AL
              ADD     AL,CH                 ;Add seconds quotient
              CBW                           ;Byte to word in AX
              DIV     CL                    ;Divide minutes by 60

              MOV     Current_Time.Min,AH   ;Save minutes
              CALL    Bin_to_ASCII24        ;Write minutes to Clock_Text

              MOV     AL,Current_Time.Hrs   ;Hours in AL
              ADD     AL,CH                 ;Add minutes quotient

              Cmp     AL,24
              Jb      Savehours

              Mov     AL,0                  ;reset to 0 @ 2400 hours
Savehours:    MOV     Current_Time.Hrs,AL   ;
              CBW                           ;Byte to word in AX
              Xchg    AL,AH



Cont:         CALL    Bin_to_ASCII24        ;Write hours to Clock_Text






Write_Time:   MOV     ES,Video_Buffer       ;Set ES to screen segment
              LEA     SI,Clock_Text         ;Point SI to text storage
              MOV     AH,Attribute          ;Color to use in AH
              MOV     DI,Video_Offset       ;Get display location
              MOV     DX,3DAh               ;CGA Mode Status Register in DX
              MOV     CX,8                  ;8 characters to print
              CLD                           ;Clear DF for string moves

Output1:      CMP     Adapter,2             ;Are we doing CGA?
              JNE     Output2               ;If not, skip the retrace stuff

No_Retrace:   IN      AL,DX                 ;Get the video status byte
              TEST    AL,1                  ;Horizontal retrace active?
              JNE     No_Retrace            ;Yes, wait until it's over
              CLI
Retrace:      IN      AL,DX                 ;Get the video status byte again
              TEST    AL,1                  ;Horizontal retrace active?
              JE      Retrace               ;No, wait until the next one

Output2:      LODSB                         ;Character in AL
              STOSW                         ;Display character/attribute pair
              STI                           ;.003
              LOOP    Output1               ;Continue until done CX times

              MOV     Counter,18            ;Start count over again

Done:         POP     ES                    ;Restore all registers
              POP     DS
              POP     DI
              POP     SI
              POP     DX
              POP     CX
              POP     AX
              RET
Do_Clock24    Endp

;----------------------------------------------------------------------------
;BIN_TO_ASCII converts a single hex byte to its 2 character ASCII equivalent
;and stores those characters in Clock_Text.
;----------------------------------------------------------------------------

Bin_to_ASCII24  Proc    Near
              MOV     CH,AL                 ;Save prior quotient in CH
              MOV     AL,AH                 ;Put number into AL
              CBW                           ;Byte to word in AX
              DIV     DL                    ;Divide AL by 10
              ADD     AL,48                 ;Convert quotient to ASCII
              MOV     [DI],AL               ;Store digit in Clock_Text
              INC     DI                    ;Point to next digit
              ADD     AH,48                 ;Convert remainder to ASCII
              MOV     [DI],AH               ;Store digit in Clock_Text
              SUB     DI,4                  ;Point DI to 3rd prior digit
              RET
Bin_to_ASCII24  Endp

;----------------------------------------------------------------------------
;INITIALIZE sets the values of various parameters required during execution.
;----------------------------------------------------------------------------

Initialize24  Proc    Near

;Derive the offset address in video memory for location row%, column%.

              MOV     AL,160                ;160 bytes per row
              MUL     DH                    ;AX = offset value of row%
              SHL     DL,1                  ;column% * 2
              XOR     DH,DH                 ;Byte to word in DX
              ADD     AX,DX                 ;Add the two
              MOV     Video_Offset,AX       ;Store offset internally

              MOV     Attribute,BL          ;Store color% internally

;Identify the display type and set monitor-dependent values accordingly.

              CMP     Adapter,0             ;Have we done this before?
              JNE     Init_Exit             ;Yes, don't repeat
              MOV     AX,40h                ;Set ES to the BIOS data segment
              MOV     ES,AX
              MOV     BX,0B000h             ;Set Monochrome segment for now
              MOV     DL,1                  ;Set Monochrome adapter for now
              MOV     AL,ES:[63h]           ;Get type of video display
              CMP     AL,0B4h               ;Monochrome adapter?
              JE      Save_Values           ;Yes, save values
              ADD     BX,800h               ;Set BX to color screen segment
              INC     DL                    ;and increase DL to 2
              PUSH    BX
              MOV     AH,12h                ;request EGA info service
              MOV     BL,10h
              INT     10h
              CMP     BL,10h                ;Is an EGA installed?
              POP     BX
              JE      Save_Values           ;No, leave DL set to 2
              INC     DL                    ;Yes, increase DL to 3
Save_Values:  MOV     Video_Buffer,BX       ;Save the screen buffer address
              MOV     Adapter,DL            ;Save our adapter code
Init_Exit:    RET
Initialize24  Endp

Code          Ends
              End
