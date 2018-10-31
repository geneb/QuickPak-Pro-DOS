;----- Extern2.Asm - "DATA" statements for Date2Num.Asm and Num2Date.Asm

;Copyright (c) 1988 Ethan Winer


Public Year, Month, Day, Days, LpYear, Table, YrDays, Ad, Ad2

.Model Medium
.Data

    Year    DW ?
    Month   DB ?
    Day     DB ?
    Days    DW ?
    LpYear  DB ?
    Table   DW 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365
    YrDays  DW ?
    Ad      DB ?
    Ad2     DB ?

End
