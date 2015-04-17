; Executable name	 : hexdump2
; Version		 : 1.0
; Created date		 : 4/15/2015
; Last Update		 : 4/15/2015
; Author		 : Abhineet Sharma(ref. Jeff Duntemann)
; Description 		 : conversion of binary values to hexadecimal strings
; 
; Run it this way
; 	hexdump1 < (input file)
; Build using the Make file in this folder
;
;

SECTION .bss			; section containig uninitialised data

	BUFFLEN equ 1024	; Length of buffer, we read the file 16 bits at a time
	Buff:	resb BUFFLEN	; Text buffer itself

SECTION .data			; section containing initialised data

; Here we have two parts of a single data structure; Implementing the text line of 
; a hexdump utility. The first part displays 16 bytes in hex separated by spaces.
; Immediately following is a 16-character line delimited by vertical bar characters.
; Because they are adjacent, the two parts can be referenced separately or as a single
; contiguous unit. Remember that if DumpLin is to be used separately, you must appeand an
; EOL before sending it to linux console. 

	DumpLin: db "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00"
	DUMPLEN	equ $-DumpLin
	ASCLin:	db "|..................|", 10
	ASCLEN	EQU $-ASCLin
	FULLLEN	EQU $-DumpLin
	
; The HexDigits table is used to convert numeric values to their hex equivalents. Index
; by nybble without a scale: [HexDigits+eax]

	HexDigits: db "0123456789ABCDEF"
	
; This table is used for ASCII character translation, into the ASCII portion of the hex 
; dump line, via XLAT or ordinary memory look up. All printable characters "play through"
; as themselves. The hight 128 characters are translated to ASCII period (2E). 
; The non-printable characters in the lower 128 are also converted to ASCII period, as is 
; char 127.
; 

	DotXlat:
		db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
		db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
		db 20h,21h,22h,23h,24h,25h,26h,27h,28h,29h,2Ah,2Bh,2Ch,2Dh,2Eh,2Fh
		db 30h,31h,32h,33h,34h,35h,36h,37h,38h,39h,3Ah,3Bh,3Ch,3Dh,3Eh,3Fh
		db 40h,41h,42h,43h,44h,45h,46h,47h,48h,49h,4Ah,4Bh,4Ch,4Dh,4Eh,4Fh
		db 50h,51h,52h,53h,54h,55h,56h,57h,58h,59h,5Ah,5Bh,5Ch,5Dh,5Eh,5Fh
		db 60h,61h,62h,63h,64h,65h,66h,67h,68h,69h,6Ah,6Bh,6Ch,6Dh,6Eh,6Fh
		db 07h,71h,72h,73h,74h,75h,76h,77h,78h,79h,7Ah,7Bh,7Ch,7Dh,7Eh,2Eh
		db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
		db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
		db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
		db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
		db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
		db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
		db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
		db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
		

SECTION .text			; section containing code

;------------------------------------------------------------------------------------------
; ClearLine:	clear a hex dump line string to 16 0 values
; Updated:	4/16/2015
; In:		Nothing
; Returns:	Nothing
; Modifies:	Nothing
; Calls:	DumpChar
; Description:	the hex dump line string is cleared to binary zero by calling DumpChar 16
; 		times, passing it 0 each time.

ClearLine:
	  Pushad 		; save all caller's GP registers
	  mov edx, 15		; we're going to go 16 pokes, counting from 0
  .poke:  mov eax, 0		; Tell DumpChar to poke a 0
	  call DumpChar		; Insert the 0 into hex dump string
	  sub edx, 1		; decrement doesn't affect CF
	  jae .poke		; loop back if EDX >= 0
	  popad			; restore all GP registers
	  ret			; Go home
	  
	  
; -----------------------------------------------------------------------------------------
; DumpChar:	poke a value into the hex dump line string
; Updated:	4/16/2015
; In:		pass the 8-bit value to be poked in EAX
;		pass the value's position in the line (0-15) in EDX
; Returns:	Nothing
; Modifies	EAX, ASCLin, DumpLin
; Calls:	Nothing
; Description:	The value put in EAX will be put both in hex dump portion and ASCII portion,
;		at the position passed in EDX, represented by a space where it is not a 
;		printable character.

DumpChar:
	  push ebx		; save caller's EBX
	  push edi		; save caller's EDI
	  
; First we insert input character into ASCII portion of Dump Line
	  mov bl, byte [DotXlat+eax]	; translate non-printables to .
	  mov byte [ASCLin+edx+1],bl	; write to ASCII portion
	  
; next we insert the hex equivalent of the input character in the hex portion of hex dump
; line.
	  mov ebx, eax			; save a second copy of the input characters
	  lea edi, [edx*2+edx]		; calculate offset into line string (EDX X 3)
	  
; look up low nybble character and insert it into the string:
	  and eax, 0000000Fh		; mask out all but the low nybble 
	  mov al, byte [HexDigits+eax]	; look up the character equivalent of the nybble
	  mov byte [DumpLin+edi+2],al	; write the character equivalent to line string
	  
; look up the high nybble character and insert it into the string
	  and ebx, 000000F0h		; mask out all but the second-lowest nybble
	  shr ebx, 4			; shift high 4-bits of the byte into low 4-bits
	  mov bl, byte[HexDigits+ebx]	; look up character equivalent of nybble
	  mov byte [DumpLin+edi+1],bl	; write the character equiv to line string
	  
; Done!
	  pop edi			; restore caller's edi
	  pop ebx			; restore caller's ebx
	  ret
	  
; ---------------------------------------------------------------------------------------------
; PrintLine:	displays DumpLin to stdout
; Updated:	4/17/2015
; In:		Nothing
; Returns:	Nothing
; Modifies:	Nothing
; Calls:	kernel sys_write
; Description:	the hex dump line string DumpLin is displayed to stdout using INT 80h sys_write
;		All GP registers are preserved

PrintLine:
	  pushad			; save all GP registers
	  mov eax, 4			; specify sys_write call
	  mov ebx, 1			; specify file descritor 1: standard output
	  mov ecx, DumpLin		; pass offset of line string
	  mov edx, FULLLEN		; pass size of line string
	  int 80h			; make kernel call to display line string
	  popad				; restore all GP registers of caller
	  ret
	  
; ---------------------------------------------------------------------------------------------
; LoadBuff:	fills a buffer with data from stdin via INT 80 sys_read
; updated:	4/17/2015
; IN:		NOTHING
; Returns: 	# of bytes read in EBP
; Modifies:	ECX, EBP, Buff
; Calls:	kernel sys_write
; Description:	loads a buffer full of data [BUFFLEN bytes] from stdin using INT 80h sys_read 
;		and placed it in Buff. Buffer offset counter ECX is zeroed, because we are
;		starting on a new buffer full of data. 

LoadBuff:
	  push eax			; save caller's eax
	  push ebx			; save caller's ebx
	  push edx			; save caller's edx
	  mov eax, 3			; specify sys_read call
	  mov ebx, 0			; specify file descriptor 0: standard input
	  mov ecx, Buff			; pass offset of buffer to read to
	  mov edx, BUFFLEN		; pass number of bytes to read at one pass
	  int 80h			; call sys_read to fill the buffer
	  mov ebp, eax			; save # of bytes read from file for later
	  xor ecx, ecx			; clear buffer pointer ecx to 0
	  pop edx
	  pop ebx			; restore EBX
	  pop eax			; restore caller's EAX
	  ret
	  
global _start			; linker needs this to find entry point

; -----------------------------------------------------------------------------------------------
; MAIN PROGRAM BEGINS NOW
;------------------------------------------------------------------------------------------------

_start:
	  nop

; whatever initialization needs doing before the loop scan starts is here:

	  xor esi, esi			; clear total byte counter to 0
	  call LoadBuff			; read first buffer of data from stdin
	  cmp ebp, 0			; if EBP=0, sys-read reached EOF on stdin
	  jbe Exit			; 
	  
; Go through the buffer and convert binary byte values to hex equivalents:

Scan:
	  xor eax, eax			; clear out eax
	  mov al, byte [Buff+ecx]	; get a byte from buffer into AL
	  mov edx, esi			; copy total counter to EDX
	  and edx, 0000000Fh		; mask out lowest 4-bit character of char counter
	  Call DumpChar			; call character poke procedure
	  
; Bump the buffer pointer to the next character and see if buffer's done:

	  inc esi			; increment total characters processed counter
	  inc ecx			; increment buffer pointer
	  cmp ecx, ebp			; compare with # characters in buffer
	  jb .modTest			; if we have processed all chars in buffer
	  call LoadBuff			; fill the buffer again
	  cmp ebp, 0			; if EBP=0, sys-read reached EOF on stdin
	  jbe Done
	  
; See whether we are done processing one set of 16 and are ready to display a line:

.modTest:
	  test esi, 0000000Fh		; Test lowest 4-bits in counter for 0
	  jnz Scan			; if the counter is *not* modulo 16, loop back
	  call PrintLine		; otherwise print a line
	  call ClearLine		; clear hex dump line to 0
	  jmp Scan			; continue scanning the buffer
	  
; Exiting the routine

Done:
	  call PrintLine		; print the "leftovers" line

Exit:
	  mov eax, 1			; code for exit syscall
	  mov ebx, 0			; return a code of zero
	  int 80H			; make kernel call