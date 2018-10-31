;********** Fact.Asm - derives a factorial for numbers between 0 and 170

;Copyright (c) 1988 Ethan Winer

;Syntax: Answer# = Factorial#(Number%)
;
;where Answer# will receive the factorial of Number%, or -1 if
;Number% is outside the range 0 to 170.
;
;Computing factorials generally takes an enormous amount of time
;because so many double precision numbers must be multiplied.  The
;approach we have taken here is to instead calculate all of the
;answers ahead of time, and place them into a table.  This way,
;Factorial can quickly look up the correct answer.
;
;This table is stored in the Code Segment, to avoid stealing any
;string space from BASIC.  None the less, you may edit the table
;to shorten it if you don't need the wide range of factorials this
;program can accommodate.  We recommend that you remark out the
;table entries rather than remove them permanently.  If you do
;this, be sure to also change the test that compares the incoming
;value to 170.


.Model Medium,BASIC

.Data

    Minus1   DQ -1.0      ;a minus 1 to copy as an error
    DummyAdr DW ?         ;where BASIC wants us to leave the returned value

.Code
Factorial Proc Uses ES DS SI DI, Number:Ptr, Dummy:Ptr

    Mov  AX,DS            ;copy DS into ES for Movs below
    Mov  ES,AX

    Mov  SI,Offset Minus1 ;assume an error for now
    Mov  DI,Dummy         ;get the dummy address BASIC gave us
    Mov  DummyAdr,DI      ;save it locally for later

    Mov  CX,4             ;prepare to move 4 words
    Cld                   ;clear the direction flag to move bytes forward
    Rep  Movsw            ;copy the -1 into the function output

    Mov  SI,Number        ;get the address for Number%
    Mov  CX,[SI]          ;put it into CX
    Or   CX,CX            ;is it less than zero?
    Js   Exit             ;yes, bag out
    Cmp  CX,170           ;is it greater than 170?
    Ja   Exit             ;yes

    Mov  AX,8             ;set AX to the size of each table entry
    Mul  CL               ;now AX holds the offset into Table to the answer
    Mov  SI,Offset Table
    Add  SI,AX            ;transfer it into SI
    Mov  DI,DummyAdr      ;point DI to the dummy address
    
    Mov  CX,4             ;prepare to move four words
    Mov  AX,CS            ;set DS to the code segment
    Mov  DS,AX
    Rep  Movsw            ;move the correct four words into Result

Exit:
    Mov  AX,ES            ;restore DS before returning to BASIC
    Mov  DS,AX
    Mov  AX,Dummy         ;put the function output address in DX:AX as per
    Mov  DX,SS            ;  Microsoft's Mixed Language Programming Guide
    Ret

Table:

DQ   1.0                               ; 0
DQ   1.0                               ; 1
DQ   2.0                               ; 2
DQ   6.0                               ; 3
DQ   24.0                              ; 4
DQ   120.0                             ; 5
DQ   720.0                             ; 6
DQ   5040.0                            ; 7
DQ   40320.0                           ; 8
DQ   362880.0                          ; 9
DQ   3628800.0                         ; 10
DQ   39916800.0                        ; 11
DQ   479001600.0                       ; 12
DQ   6227020800.0                      ; 13
DQ   87178291200.0                     ; 14
DQ   1307674368000.0                   ; 15
DQ   20922789888000.0                  ; 16
DQ   355687428096000.0                 ; 17
DQ   6402373705728000.0                ; 18
DQ   1.21645100408832E+17              ; 19
DQ   2.43290200817664E+18              ; 20
DQ   5.109094217170944E+19             ; 21
DQ   1.124000727777608E+21             ; 22
DQ   2.585201673888498E+22             ; 23
DQ   6.204484017332394E+23             ; 24
DQ   1.551121004333098E+25             ; 25
DQ   4.032914611266057E+26             ; 26
DQ   1.088886945041835E+28             ; 27
DQ   3.048883446117138E+29             ; 28
DQ   8.841761993739701E+30             ; 29
DQ   2.652528598121911E+32             ; 30
DQ   8.222838654177924E+33             ; 31
DQ   2.631308369336936E+35             ; 32
DQ   8.683317618811889E+36             ; 33
DQ   2.952327990396041E+38             ; 34
DQ   1.033314796638614E+40             ; 35
DQ   3.719933267899013E+41             ; 36
DQ   1.376375309122635E+43             ; 37
DQ   5.23022617466601E+44              ; 38
DQ   2.039788208119745E+46             ; 39
DQ   8.15915283247898E+47              ; 40
DQ   3.34525266131638E+49              ; 41
DQ   1.40500611775288E+51              ; 42
DQ   6.041526306337384E+52             ; 43
DQ   2.65827157478845E+54              ; 44
DQ   1.196222208654802E+56             ; 45
DQ   5.502622159812089E+57             ; 46
DQ   2.586232415111683E+59             ; 47
DQ   1.241391559253607E+61             ; 48
DQ   6.082818640342679E+62             ; 49
DQ   3.041409320171338E+64             ; 50
DQ   1.551118753287382E+66             ; 51
DQ   8.06581751709439E+67              ; 52
DQ   4.274883284060024E+69             ; 53
DQ   2.308436973392413E+71             ; 54
DQ   1.269640335365826E+73             ; 55
DQ   7.109985878048632E+74             ; 56
DQ   4.052691950487723E+76             ; 57
DQ   2.350561331282879E+78             ; 58
DQ   1.386831185456898E+80             ; 59
DQ   8.32098711274139E+81              ; 60
DQ   5.075802138772246E+83             ; 61
DQ   3.146997326038794E+85             ; 62
DQ   1.98260831540444E+87              ; 63
DQ   1.268869321858841E+89             ; 64
DQ   8.247650592082472E+90             ; 65
DQ   5.443449390774432E+92             ; 66
DQ   3.647111091818871E+94             ; 67
DQ   2.48003554243683E+96              ; 68
DQ   1.711224524281413E+98             ; 69
DQ   1.197857166996989E+100            ; 70
DQ   8.504785885678624E+101            ; 71
DQ   6.123445837688612E+103            ; 72
DQ   4.470115461512686E+105            ; 73
DQ   3.307885441519387E+107            ; 74
DQ   2.48091408113954E+109             ; 75
DQ   1.885494701666051E+111            ; 76
DQ   1.451830920282859E+113            ; 77
DQ   1.132428117820629E+115            ; 78
DQ   8.94618213078298E+116             ; 79
DQ   7.15694570462638E+118             ; 80
DQ   5.797126020747369E+120            ; 81
DQ   4.753643337012843E+122            ; 82
DQ   3.94552396972066E+124             ; 83
DQ   3.314240134565354E+126            ; 84
DQ   2.817104114380549E+128            ; 85
DQ   2.422709538367274E+130            ; 86
DQ   2.107757298379527E+132            ; 87
DQ   1.854826422573984E+134            ; 88
DQ   1.650795516090847E+136            ; 89
DQ   1.485715964481761E+138            ; 90
DQ   1.352001527678403E+140            ; 91
DQ   1.243841405464131E+142            ; 92
DQ   1.156772507081641E+144            ; 93
DQ   1.087366156656743E+146            ; 94
DQ   1.032997848823906E+148            ; 95
DQ   9.916779348709491E+149            ; 96
DQ   9.619275968248216E+151            ; 97
DQ   9.426890448883248E+153            ; 98
DQ   9.332621544394415E+155            ; 99
DQ   9.332621544394418E+157            ; 100
DQ   9.42594775983836E+159             ; 101
DQ   9.614466715035125E+161            ; 102
DQ   9.902900716486178E+163            ; 103
DQ   1.029901674514563E+166            ; 104
DQ   1.081396758240291E+168            ; 105
DQ   1.146280563734709E+170            ; 106
DQ   1.226520203196137E+172            ; 107
DQ   1.324641819451829E+174            ; 108
DQ   1.443859583202494E+176            ; 109
DQ   1.588245541522742E+178            ; 110
DQ   1.762952551090246E+180            ; 111
DQ   1.974506857221075E+182            ; 112
DQ   2.231192748659814E+184            ; 113
DQ   2.543559733472186E+186            ; 114
DQ   2.925093693493014E+188            ; 115
DQ   3.393108684451899E+190            ; 116
DQ   3.96993716080872E+192             ; 117
DQ   4.68452584975429E+194             ; 118
DQ   5.574585761207606E+196            ; 119
DQ   6.689502913449135E+198            ; 120
DQ   8.094298525273444E+200            ; 121
DQ   9.875044200833601E+202            ; 122
DQ   1.214630436702533E+205            ; 123
DQ   1.506141741511141E+207            ; 124
DQ   1.882677176888926E+209            ; 125
DQ   2.372173242880048E+211            ; 126
DQ   3.012660018457662E+213            ; 127
DQ   3.856204823625808E+215            ; 128
DQ   4.974504222477287E+217            ; 129
DQ   6.466855489220473E+219            ; 130
DQ   8.471580690878813E+221            ; 131
DQ   1.118248651196004E+224            ; 132
DQ   1.487270706090685E+226            ; 133
DQ   1.99294274616152E+228             ; 134
DQ   2.690472707318049E+230            ; 135
DQ   3.659042881952548E+232            ; 136
DQ   5.012888748274988E+234            ; 137
DQ   6.917786472619482E+236            ; 138
DQ   9.615723196941089E+238            ; 139
DQ   1.346201247571752E+241            ; 140
DQ   1.898143759076171E+243            ; 141
DQ   2.695364137888163E+245            ; 142
DQ   3.854370717180069E+247            ; 143
DQ   5.550293832739308E+249            ; 144
DQ   8.047926057471989E+251            ; 145
DQ   1.174997204390911E+254            ; 146
DQ   1.72724589045464E+256             ; 147
DQ   2.556323917872864E+258            ; 148
DQ   3.808922637630569E+260            ; 149
DQ   5.713383956445857E+262            ; 150
DQ   8.627209774233244E+264            ; 151
DQ   1.311335885683453E+267            ; 152
DQ   2.006343905095684E+269            ; 153
DQ   3.089769613847352E+271            ; 154
DQ   4.789142901463393E+273            ; 155
DQ   7.471062926282892E+275            ; 156
DQ   1.172956879426413E+278            ; 157
DQ   1.853271869493735E+280            ; 158
DQ   2.946702272495036E+282            ; 159
DQ   4.714723635992061E+284            ; 160
DQ   7.590705053947223E+286            ; 161
DQ   1.229694218739449E+289            ; 162
DQ   2.004401576545303E+291            ; 163
DQ   3.287218585534299E+293            ; 164
DQ   5.423910666131583E+295            ; 165
DQ   9.003691705778434E+297            ; 166
DQ   1.503616514864998E+300            ; 167
DQ   2.526075744973199E+302            ; 168
DQ   4.269068009004706E+304            ; 169
DQ   7.257415615308004E+306            ; 170

Factorial Endp
End
