On October 26th, 2018 I purchased the software assets of Full Moon Software.
Full Moon Software used to be known as Crescent Software.  They produced a line
of excellent development libraries for MS-DOS.  The supported environments were
QuickBASIC 4.x, Microsoft Professional Development System v7.x, and Visual 
Basic for DOS.

The idea behind obtaining these products was to release them to the public
domain to ensure that people could still access these things in the future.
While most developers will have no use for these products in a modern 
develoment environment, they still have value as an example of "how it was 
done" back in the heyday of x86 DOS development. 

The software in this repository hasn't been modified from how I received it 
from Ethan Winer, the original author.  While all the source files carry some 
kind of Copyright notice, the software is now in the public domain.

The original distribution disk files and documentation are available here:

http://annex.retroarchive.org/crescent/index.html

Gene Buckle, October 27th, 2018
-------------------------------------------------------------------------------
About Crescent Software:
After 20 years as a professional recording engineer and musician, Ethan
Winer founded Crescent Software in 1986, quickly building it to become the
leading provider of add-on products for use with Microsoft compiled BASIC
for DOS. During that time Ethan wrote numerous articles about DOS BASIC and
assembly language for all of the major programming magazines, and also
served as a contributing editor for PC Magazine. Ethan also received
Microsoft's MVP award every year since 1996 for his assistance in the
Microsoft BASIC programming newsgroups. In 1992 Ethan sold Crescent to his
partner Don Malin, and retired in order to pursue his musical interests.
===============================================================================

I've attached the text from Full Moon Software's catalog description of 
QuickPak Professional below.

-------------------------------------------------------------------------------
QUICKPAK(tm) PROFESSIONAL FOR DOS
=================================

The Most Comprehensive Collection of BASIC Tools Ever Produced
--------------------------------------------------------------

QuickPak Professional is a programmer's toolbox of more than 500 BASIC and 
assembly language subroutines, designed to help developers improve the quality 
of their programs and complete them faster. Included are routines for 
windowing, access to DOS and BIOS services, searching and sorting any type of 
BASIC array, creating pull-down and Lotus(r) style menus, accepting data 
input, and much more.
     Extensive documentation (700 pages) is provided with additional tutorials 
on files, arrays, subprograms, sorting, compiling and linking, plus many other 
related topics. The manual is clearly written, and includes a wealth of 
information useful and pertinent for programmers at all levels of experience. 
We provide pre-built Quick and linking libraries for use with all current 
versions of Microsoft BASIC for DOS--simply load the appropriate library, and 
you're ready to go. The high-level routines written in BASIC are easily loaded 
as source modules.

QUICKPAK IS EASY TO USE

All of the routines in QuickPak Professional are extremely easy to use. The 
number of parameters is kept to an absolute minimum, and detailed instructions 
are included for each routine. Where appropriate, the routines are designed as 
functions that return a value directly. For example, to read the disk volume 
label for Drive A:

     Volume$ = GetVol$("A")

The DOS services permit many operations that are not possible using BASIC 
alone. Routines are included to obtain a list of file and directory names from 
disk, retrieve and set the default drive, copy files, determine the total and 
free space on a disk, read or change a file's date, time, and attributes, and 
directly read or write disk sectors. A complete set of file and printer 
routines is also provided to eliminate the need for ON ERROR.
     Other low-level routines include string and file encryption, file and 
array searching and sorting, date and time calculations, access to mouse 
services, and extensive string manipulation. A sophisticated Print Screen 
routine operates in all BASIC-supported graphics modes and works with any 
printer that honors either the standard Epson/IBM dot matrix or HP LaserJet 
control codes.
     All of the routines that process strings and string arrays are also 
provided in an alternate version that ignores capitalization. The video 
routines operate on any screen page and automatically support the 43- and 50-
line EGA and VGA text modes.

IF YOU NEED IT, QUICKPAK PROBABLY HAS IT

QuickPak Professional also includes many complete applications that may be 
added to your programs.  Dozens of callable BASIC modules are provided, such 
as a spreadsheet and a full-featured text editor with word wrap, row and 
column block operations, and built-in mouse support. Other routines include a 
pop-up calculator, calendar, ASCII chart, file manager, plus a browse program 
that handles text files of nearly any size.
     Additional major utilities are a complete pulldown menu system with mouse 
support, vertical scrolling menus that accommodate any number of choices, and 
recursive TYPE array and file sort routines that can handle any number of sort 
keys. The editor and menu subprograms operate either normally, or in a unique 
multi-tasking mode that lets you display several menus at once and poll them 
in sequence. Also supplied is a comprehensive set of financial and scientific 
functions, including every function offered in commercial spreadsheet 
programs.
     Many routines are provided for sophisticated window handling. The window 
manager accommodates up to ten levels of window nesting and may be easily 
expanded to handle even more screens if needed. A special assembler routine 
lets you close just a portion of a larger window. Other unique subroutines let 
you write to two monitors at once, create bit arrays that occupy just one bit 
per element, run .BAT and .COM files, evaluate complex numeric expressions, 
create delays with microsecond accuracy, and load or save entire string arrays 
to disk many times faster than is possible using BASIC alone.

THE BEST FEATURES

Other unique features include routines for storing screens and data in 
expanded (EMS) or extended (XMS) memory, a string manager that overcomes 
QuickBASIC's 64k limit on string data, and a greatly simplified method for 
handling DOS errors. Tutorials include a comparison of procedure methods, 
dynamic versus static arrays, saving text and graphics images to disk, 
debugging, calling QuickPak routines from a pure assembly language program, 
and a discussion about handling critical errors. Current versions of QuickPak 
Professional also include the following features added in version 4:

     * A full complement of mouse-aware dialog box routines that support
       polling, command and option buttons, check boxes, text entry fields,
       and list fields (vertical menus).

     * A masked input routine that lets you specify valid data types (letters,
       numbers, convert to caps, etc.) for each character position in the
       field. Any characters may be used as field delimiters (such as the
       dashes in a Date or Social Security Number field), and they are skipped
       over automatically during data entry.

     * A real expression solver that lets you enter variable names and
       assignments, perform calculations, and even set up Watch expressions
       just like the BASIC editor.

     * Numerous low-level routines can search all of memory for a string, tell
       if a key on the PC's keyboard is currently being pressed and held,
       parse strings using multiple delimiters, execute another program and
       retrieve its return code (DOS error level), search the PATH for a file,
       read CMOS setup information, determine drive types and tell if they are
       fixed or floppy or on a network, and much more.

THE FULL MOON PHILOSOPHY

Full Moon Software is owned and operated by Ethan Winer, author of QuickPak 
Professional and P.D.Q. Ethan is well-known for his innovation and leadership 
in the BASIC add-ons market, and for his many contributions to PC Magazine, 
Microsoft Systems Journal, and other programming magazines. His products have 
won numerous "Editor's Choice" awards including BASICPro (now VB Programmers 
Journal), Byte, and Databased Advisor.
     As with all our products, full source code is provided at no additional 
cost, so you can see how the routines were designed and even modify them if 
you want. We genuinely want you to understand how our libraries work and be 
able to learn from them. All of our products are reasonably priced and include 
free technical assistance, but they are licensed for use by only one person 
using one computer at a time. Royalty payments are not required when our 
routines are incorporated into your compiled applications. However, you may 
not distribute our source, object, or library files. If your customers need to 
rebuild your program, they will need their own copy of our product(s).

THE BOTTOM LINE

QuickPak Professional for DOS costs $199 and works with QuickBASIC 4.x, PDS 
7.x, and VB/DOS. Add $8 for UPS ground shipping to US addresses only (no P.O. 
boxes); Connecticut residents must add 6.0% sales tax or show proof of tax-
exempt status when ordering. Please call us for overnight and foreign shipping 
costs. We accept checks, MasterCard, and VISA. We do accept purchase orders, 
but they must be accompanied by full payment.

QuickPak(tm) is a trademark of Crescent Software, Inc.

