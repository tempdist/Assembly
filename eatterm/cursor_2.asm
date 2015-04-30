; Executable name:  eatterm
; Version:          1.0
; Created date:     4/29/2015
; Last update:      4/29/2015
; Author:           Abhineet Sharma(ref Jef Dunttemann)
; Description:	    A simple program in assembly for Linux, using
; 		    NASM 2.05, demonstrating the use of escape
; 		    sequences to do simple “full-screen" text output.
;
; Build using these commands:
; nasm -f elf -g -F stabs eatterm.asm
; ld -o eatterm eatterm.o
;
;

SECTION .data				      ; section containing initialised data

SCRWIDTH:	  EQU 80		      ; by default assume 80 characters wide
PosTerm:	  db 27, "[01;01H"	      ; <ESC>[<Y>;<X>H
POSLEN:		  equ $-PosTerm		      ; Length of term position string
ClearTerm: 	  db 27, "[2J"		      ; <ESC>[2J
CLEARLEN 	  equ $-ClearTerm	      ; Length of term clear string
AdMsg:		  db "Death of a Star!"	      ; Ad message
ADLEN:		  equ $-AdMsg		      ; Length of ad message
Prompt:		  db "Press Enter: "	      ; User prompt
PROMPTLEN:	  equ $-Prompt		      ; Length of user prompt

; This table gives us pairs of ASCII digits from 0-80. Rather than
; calculating ASCII digits to insert in the terminal control string,
; we look them up in the table and read back two digits at once to
; a 16-bit register like DX, which we then poke into the terminal
; control string PosTerm at the appropriate place. See GotoXY.
; If you intend to work on a larger console than 80 X 80, you must
; add additional ASCII digit encoding to the end of Digits. Keep in
; mind that the code shown here will only work up to 99 X 99.

Digits: 	db "0001020304050607080910111213141516171819"
		db "2021222324252627282930313233343536373839"
		db "4041424344454647484950515253545556575859"
		db "606162636465666768697071727374757677787980"

SECTION .bss				       ; section containing uninitialised data


SECTION .text				       ; section containing code

; ------------------------------------------------------------------------------
; ClrScr:	clear the Linux Console
; Updated:	4/29/2015
; In:		Nothing
; Returns:	Nothing
; Modifies	Nothing
; Calls:	kernel sys_write
; Description: 	sends the predefined control string <ESC>[2J to the console,
;               which clears the full display
;
;

ClrScr:
	push eax			        ; save pertinent registers
	push ebx
	push ecx
	push edx
	mov ecx, ClearTerm		        ; Pass offset of terminal control string
	mov edx, CLEARLEN		        ; pass the length of terminal control string
	call WriteStr			        ; send control string to console
	pop edx				        ; restore pertinent registers
	pop ecx
	pop ebx
	pop eax
	ret				        ; go home

; ------------------------------------------------------------------------------
; GotoXY:	        position the linux console cursor to an X,Y positision
; UPDATED: 	        4/29/2015
; In:		        X in AH, Y in AL
; Returns:	        Nothing
; Modifies:	        PosTerm terminal control sequence string
; calls: 	        kernel sys_write
; Description: 	        prepares a terminal control string for the X, Y coordinates
;		        passed in AL and AH and calls sys_write to position the console
;		        cursor to that X,Y position. Writing text to the console after
;		        GotoXY will begin display of text at that X,Y position.

GotoXY:
	pushad				         ; save caller's registers
	xor ebx, ebx			         ; zero EBX
	xor ecx, ecx			         ; Ditto ECX

; Poke the Y digits:
	mov bl, al			         ; put Y value into scale term EBX
	mov cx, word [Digits+ebx*2]	         ; fetch decimal digits to CX
	mov word [PosTerm+2], cx	         ; poke digits into control string
; Poke the X digits:
	mov bl, ah			         ; put Y value into scale term EBX
	mov cx, word [Digits+ebx*2]	         ; fetch decimal digits to CX
	mov word [PosTerm+5], cx	         ; poke digits into control string
; Send control sequence to stdout:
	mov ecx, PosTerm		         ; pass address of the control string
	mov edx, POSLEN			         ; pass the length of the control string
	call WriteStr			         ; send control string to the console
; Wrap up and go home:
	popad
	ret				         ; go home

; ------------------------------------------------------------------------------
; WriteCtr:	    send a string centered to an 80-char wide linux console
; Updated:	    4/29/2015
; In:		    Y value in AL, string address in ECX, string length in EDX
; returns:	    nothing
; modifies:	    PosTerm terminal control sequence string
; calls:	    GotoXY, WriteStr
; Description:	    Displays a string to Linux console centered in an 80-clumn
;                   display.Calculates the X for the passed-in string length,
;                   then calls GotoXY and WriteStr to send the string to the
;                   console.
;

WriteCtr:
	push ebx			          ; save caller's EBX
	xor ebx, ebx			          ; zero EBX
	mov bl, SCRWIDTH		          ; load the screen width value to BL
	sub bl, dl			          ; Take diff. of screen width and string length
	shr bl, 1                         	  ; divide the difference by 2 for X value
	mov ah, bl                        	  ; GotoXY requires X value in AH
	call GotoXY                       	  ; position cursor for display
	call WriteStr                     	  ; write the string to the console
	pop ebx                           	  ; restore caller's EBX
	ret                               	  ; go home

;-------------------------------------------------------------------------
; WriteStr:     Send a string to the Linux console
; UPDATED:      4/30/2015
; IN:           String address in ECX, string length in EDX
; RETURNS:      Nothing
; MODIFIES:     Nothing
; CALLS:        Kernel sys_write
; DESCRIPTION:  Displays a string to the Linux console through a
;               sys_write kernel call

WriteStr:
	push eax                          	  ; save pertinent registeres
	push ebx
	mov eax, 4                        	  ; specify sys_write call
	mov ebx, 1                        	  ; specify file descriptor: 1, stdout
	int 80H                           	  ; make the kernel call
	pop ebx
	pop eax
	ret                               	  ; go home

global _start                        		  ; linker needs this to find the entery point
_start:

	nop
; first we clear the screen display
	call ClrScr
; then we post the ad message centered on the 80-wide console:
	mov al, 12                    ; Specy line 12
	mov ecx, AdMsg                ; pass address of message
	mov edx, ADLEN                ; pass length of message
	call WriteCtr                 ; display to the console

; position the cursor for the "press enter" prompt:
	mov ax, 0117h                 ; X,Y = 1,23 as a single hex value in AX
	call GotoXY                   ; position the cursor

; Display the "press enter" prompt:
	mov ecx, Prompt               ; pass offset of the prompt
	mov edx, PROMPTLEN            ; pass the length of prompt
	call WriteStr                 ; send the prompt to the console

; wait for the user to press enter:
	mov eax, 3                    ; code for sys_read
	mov ebx, 0                    ; specify file descriptor 0: stdin
	int 80H                       ; make kernel call

; ... and we're done

Exit: 	mov eax, 1                    ; code for exit syscall
	mov ebx, 0                    ; return a code for 0
	int 80H                       ; make kernel call
