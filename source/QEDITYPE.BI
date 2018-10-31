TYPE EditInfo
    Rows AS INTEGER             'Text Window Rows
    Wide AS INTEGER             '     "      Columns
    Wrap AS INTEGER             'Right Margin for Word Wrap (0 for No Wrap)
    HTab AS INTEGER             'Horizontal Tab spaces
    AColor AS INTEGER           'Window Color
    Frame AS INTEGER            'Display Frame Flag (-1 = Use frame)

    LSCol AS INTEGER            'Left Screen Column of editable window
    LC AS INTEGER               'Left Text Column
    CurCol AS INTEGER           'Current text column
    TSRow AS INTEGER            'Top Screen Row of editable window
    TL AS INTEGER               'Top Text Line
    CurLine AS INTEGER          'Current text Line

    UlCRow AS INTEGER           'Upper Left Block Row
    UlCCol AS INTEGER           'Upper Left Block Column
    BrCRow AS INTEGER           'Lower Right Block Row
    BrCCol AS INTEGER           'Lower Right Block Column
    CBlock AS INTEGER           'Column Block Flag
   
    WasMarked AS INTEGER        'Flag that something has been marked
    DelBlock AS INTEGER         'Flag to Delete hilited block
    InsBlock AS INTEGER         'Flag to Paste Buffer contents
    Text2Paste AS INTEGER       'Flag that something is in the Paste buffer
    CopyBlock AS INTEGER        'Flag to paste the buffer now

    Presses AS INTEGER          'Mouse presses.                Read Only!
    MRow AS INTEGER             'Mouse Screen Row.             Read Only!
    MCol AS INTEGER             'Mouse Screen Column.          Read Only!

    UnKnownKey AS INTEGER       'Flag, -1 if key pressed but not handled
    InsStat AS INTEGER          'Insert State (1 = Overtype, -1 = Insert)
    Changed AS INTEGER          'Flag - (-1 means text was edited)
    LCount AS INTEGER           'Number of text lines.         Read Only!
    MErr AS INTEGER             'Error flag  (1 = Out of memory)
                                '            (2 = Too many lines)
END TYPE

