; Executable name	 : hexdump1
; Version		 : 1.0
; Created date		 : 4/8/2015
; Last Update		 : 4/8/2015
; Author		 : Jeff Duntemann
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

	HexStr: db "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00", 10
	HEXLEN	equ $-HexStr

	Digits: db "0123456789ABCDEF"	

SECTION .text			; section containing code

global _start			; linker needs this to find entry point

_start:
	nop

; Read a buffer full of text from stdin:
read:
	mov eax, 3			; specify sys_read call
     	mov ebx, 0			; specify file descriptor 0: Standard Input
      	mov ecx, Buff			; pass offset of the buffer to read to
      	mov edx, BUFFLEN		; pass number of bytes to read at one pass
      	int 80h				; call sys_read to fill the buffer
      	mov ebp, eax			; save # of bytes read from file for later
      	cmp eax, 0			; If eax=0, sys_read reached EOF on stdin
      	je Done				; jump if equal to 0 from compare

; set up the registers for the process of buffer step:
	mov esi, Buff			; place the address of file buffer into esi
	mov edi, HexStr			; place address of line string into edi
	xor ecx, ecx			; clear line string pointer to 0

; go through the buffer and covert binary values to hex digits:
Scan:

	xor eax, eax			; clear eax to 0

; Here we calculate the offset into HexStr, which is the value in ecx X 3
	mov edx, ecx			; copy the character counter into edx
	shl edx, 1			; multiply the pointer by 2 using left shift
	add edx, ecx			; complete the multiplication X3

; get a character from the buffer and put it in both eax and ebx:
	mov al, byte [esi+ecx]		; put a byte from the input buffer into al
	mov ebx, eax			; Duplicate the byte in bl for second nybble

; lookup the low nybble character and insert it into the string:
	and al, 0Fh			; mask out all but low nybble 
	mov al, byte [Digits+eax]	; lookup the character equivalent of the nybble
	mov byte [HexStr+edx+2], al	; write LSB char digit to line string

; look up the high nybble and insert it into the string:
	shr bl, 4			; shift high 4 bits of characters in low 4 bits of operand
	mov bl, byte [Digits+ebx]	; lookup char equivalent of the nybble
	mov byte [HexStr+edx+1], bl	; write MSB char digit to line string

; bump the buffer pointer to the next char and see if we're done:
	inc ecx				; increment the line string pointer
	cmp ecx, ebp			; compare to the number of chars in the buffer
	jna Scan			; loop back if ecx is <= number of chars in buffer

; write the line of hexadecimal values to stdout:

	mov eax, 4			; specify sys_write call
      	mov ebx, 1			; specify file descriptor 1: standard output
      	mov ecx, HexStr			; pass offset of line string
      	mov edx, HEXLEN			; pass the size of line string
      	int 80h				; make sys_write kernel call
      	jmp read			; loop back and load another buffer full

; It's done! let's end the program:
Done:

	mov eax, 1			; code for Exist Syscall
	mov ebx, 0			; return a code of 0
	int 80H				; make kernel call

