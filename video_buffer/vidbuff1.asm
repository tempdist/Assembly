; Executable name : 	VIDBUFF1
; Version:		1.0
; Created date	:	5/1/2015
; Last update		5/1/2015
; Author:		Abhineet Sharma(ref. Jeff Duntemann)
; Description		A simple program in assembly for Linux, using NASM 2.05,
;			demonstrating string instruction operation by “faking“ full-screen
;			memory-mapped text I/O.

; Build using these commands(modify if it's being run on x86_64):
; nasm -f elf -g -F stabs vidbuff1.asm
; ld -o vidbuff1 vidbuff1.o


SECTION .data
	EOL	equ 10
	FILLCHR	equ 32					; terminal specific data, might vary with 
							; encoding and terminal in use
	HBARCHR	equ 196
	STRTROW	equ 2

; The dataset is just a table of byte-length numbers:
	Dataset db 9,71,17,52,55,18,29,36,18,68,77,63,58,44,0

	Message db "Data current as of 5/1/2015"
	MSGLEN	equ $-Message

; this escape sequence will clear the linux console and place the text 
; cursor to the origin (1,1) on virtually all linux consoles:

	ClrHome db 27, "[2J",27,"[01;01H"		; again, terminal specific string
	CLRLEN	equ $-ClrHome				; Length of term clear string

SECTION .bss						; section containing the uninitialised data
	COLS	equ 81					; Line length + 1 for EOL char
	ROWS	equ 25					; number of lines in display
	VidBuff resb COLS*ROWS				; buffer size adapts to ROWS and COLS

SECTION .text						; sectin containing code

global _start						; LINKER NEEDS THIS TO FIND ENTRY POINT

; This macro clears the linux console terminal and sets the cursor position to (1,1)
; using the single pre-defined escape sequence.

%macro ClearTerminal 0
	pushad
	mov eax, 4					; specify sys_write call
	mov ebx, 1					; specify file descriptor 1: standard output
	mov ecx, ClrHome				; pass offset of error message
	mov edx, CLRLEN					; pass the length of message
	int 80H						; make kernel call
	popad						; restore all registers
%endmacro

; ---------------------------------------------------------------------------------------------------
; ClrVid: 		Clears a text buffer to spaces and replaces all EOLs
; UPDATED: 		5/1/2015
; IN: 			Nothing
; RETURNS: 		Nothing
; MODIFIES: 		VidBuff, DF
; CALLS: 		Nothing
; DESCRIPTION: 		Fills the buffer VidBuff with a predefined character (FILLCHR) and then 
; 			places an EOL character at the end of every line, where a line ends 
; 		 	every COLS bytes in VidBuff.
;

Show:
	pushad						; save all registers
	mov eax, 4
	mov ebx, 1
	mov ecx, VidBuff				; pass offset of buffer
	mov edx, COLS*ROWS				; pass length of the buffer
	int 80H
	popad
	ret

ClrVid: 
	push eax
	push ecx
	push edi
	cld
	mov al, FILLCHR					; put the buffer filler char in AL
	mov edi, VidBuff				; point destination index at buffer
	mov ecx, COLS*ROWS				; put the count of chars stored into ECX
	rep stosb					; blast characters at the buffer

; Buffer is cleared; now we need to re-insert the EOL char after each line:

	mov edi, VidBuff				; point destination at buffer again
	dec edi							; start EOL position count at VidBuff char 0
	mov ecx, ROWS					; put number of rows in count register
	
PtEOL: 
	add edi, COLS					; add column count to EDU
	mov byte [edi], EOL				; store EOL char at the end of Row
	loop PtEOL						; Loop back if still more lines
	pop edi 						; restore caller's registers
	pop ecx
	pop eax
	ret								; go home

;-------------------------------------------------------------------------
; WrtLn: 		Writes a string to a text buffer at a 1-based X,Y position
; UPDATED: 		5/1/2015
; IN: 			The address of the string is passed in ESI
; 				The 1-based X position (row #) is passed in EBX
; 				The 1-based Y position (column #) is passed in EAX
; 				The length of the string in chars is passed in ECX
; RETURNS: 		Nothing
; MODIFIES: 		VidBuff, EDI, DF
; CALLS: 		Nothing
; DESCRIPTION: 		Uses REP MOVSB to copy a string from the address in ESI to an X,Y location
; 			in the text buffer VidBuff.

WrtLn:
	push eax
	push ebx
	push ecx
	push edi
	cld								; clear DF for up-memory write
	mov edi, VidBuff				; load destination address with buffer index
	dec eax							; Adjust Y value down by 1 for address calculation
	dec ebx							; Adjust X value down by 1 for address calculation
	mov ah, COLS					; move screen width to AH
	mul ah							; Do 8-bit multiply AL*AH to AX
	add edi, eax					; Add Y offset into Vidbuff to EDI
	add edi, ebx					; Add Y offset into Vidbuff to EDI
	rep movsb						; blast the string into the buffer
	pop edi							; restore the registers we changed
	pop ecx
	pop ebx
	pop eax 
	ret								; go home
	
;-------------------------------------------------------------------------
; WrtHB: 		Generates a horizontal line bar at X,Y in text buffer
; UPDATED: 		5/1/2015
; IN: 			The 1-based X position (row #) is passed in EBX
; 				The 1-based Y position (column #) is passed in EAX
; 				The length of the bar in chars is passed in ECX
; RETURNS: 		Nothing
; MODIFIES: 	VidBuff, DF
; CALLS: 		Nothing
; DESCRIPTION: 	Writes a horizontal bar to the video buffer VidBuff,
; 				at the 1-based X,Y values passed in EBX,EAX. The bar is
; 				“made of“ the character in the equate HBARCHR. The
; 				default is character 196; if your terminal won’t display
; 				that (you need the IBM 850 character set) change the
; 				value in HBARCHR to ASCII dash or something else supported
; 				in your terminal.

WrtHB:
	push eax
	push ebx
	push ecx 
	push edi 
	cld								; clear DF for up-memory write
	mov edi, VidBuff				; put buffer address in destination register
	dec eax
	dec ebx
	mov ah, COLS					; move screen width a AH
	mul ah							; Do 8-bit multiply AL*AH to AX
	add edi, eax					; Add Y offset into vidbuff to EDI
	add edi, ebx					; Add X offset into vidbuff to EDI
	mov al, HBARCHR					; put the character to use for the bar in AL
	rep stosb 						; blast the bar character into buffer
	pop edi
	pop ecx
	pop ebx
	pop eax
	ret								; go home
	
;-------------------------------------------------------------------------
; Ruler: 		Generates a “1234567890"-style ruler at X,Y in text buffer
; UPDATED: 		5/1/2015
; IN: 			The 1-based X position (row #) is passed in EBX
; 				The 1-based Y position (column #) is passed in EAX
; 				The length of the ruler in chars is passed in ECX
; RETURNS: 		Nothing
; MODIFIES: 	VidBuff
; CALLS: 		Nothing
; DESCRIPTION: 	Writes a ruler to the video buffer VidBuff, at the 1-based
; 				X,Y position passed in EBX,EAX. The ruler consists of a
; 				repeating sequence of the digits 1 through 0. The ruler
; 				will wrap to subsequent lines and overwrite whatever EOL
; 				characters fall within its length, if it will noy fit
; 				entirely on the line where it begins. Note that the Show
; 				procedure must be called after Ruler to display the ruler
; 				on the console.

Ruler:
	push eax
	push ebx
	push ecx
	push edi
	mov edi,VidBuff 				; Load video address to EDI
	dec eax 						; Adjust Y value down by 1 for address calculation
	dec ebx 						; Adjust X value down by 1 for address calculation
	mov ah,COLS 					; Move screen width to AH
	mul ah 							; Do 8-bit multiply AL*AH to AX
	add edi,eax 					; Add Y offset into vidbuff to EDI
	add edi,ebx 					; Add X offset into vidbuf to EDI
	
; EDI now contains the memory address in buffer where the ruler
; is to begin. Now we display the ruler starting at that position:

	mov al, '1'						; start ruler with digit '1'
	
DoChar:
	stosb							; note that there is no REP prefix
	add al, '1'						; bump the character value in AL up by 1
	aaa								; adjust AX to make it a BCD addition 
	add al, '0'						; make sure we have binary '3' in AL's nybble
	loop DoChar						; go back and do another char until ecx = 0
	pop edi
	pop ecx
	pop ebx
	pop eax 
	ret								; go home
	
; ----------------------------------------------------------------------------------------
; MAIN Program

_start:

; get the console and text display text buffer ready to go:
	ClearTerminal 					; send terminal clear string to console
	call ClrVid						; init/clear the video buffer
	
; now we display the top ruler:
	mov eax, 1						; load Y position in AL
	mov ebx, 1 						; load X position in BL
	mov ecx, COLS-1					; load ruler length to ecx
	call Ruler 						; write ruler to the buffer

; here we loop through the dataset and graph the data:
	mov esi, Dataset				; put the address of dataset in ESI
	mov ebx,1 						; Start all bars at left margin (X=1)
	mov ebp, 0						; Dataset element index starts at 0
	
.blast: 
	mov eax,ebp 					; Add dataset number to element index
	add eax,STRTROW 				; Bias row value by row # of first bar
	mov cl,byte [esi+ebp] 			; Put dataset value in low byte of ECX
	cmp ecx,0 						; See if we pulled a 0 from the dataset
	je .rule2 						; If we pulled a 0 from the dataset, we’re done
	call WrtHB 						; Graph the data as a horizontal bar
	inc ebp 						; Increment the dataset element index
	
	jmp .blast 						; Go back and do another bar
; Display the bottom ruler:
.rule2: 
	mov eax,ebp 					; Use the dataset counter to set the ruler row
	add eax,STRTROW 				; Bias down by the row # of the first bar
	mov ebx,1 						; Load X position to BL
	mov ecx,COLS-1 					; Load ruler length to ECX
	call Ruler 						; Write the ruler to the buffer
; Thow up an informative message centered on the last line

	mov esi,Message 				; Load the address of the message to ESI
	mov ecx,MSGLEN 					; and its length to ECX
	mov ebx,COLS 					; and the screen width to EBX
	sub ebx,ecx 					; Calc diff of message length and screen width
	shr ebx,1 						; Divide difference by 2 for X value
	mov eax,24 						; Set message row to Line 24
	call WrtLn 						; Display the centered message
; Having written all that to the buffer, send the buffer to the console:
	call Show 						; Refresh the buffer to the console
Exit: 
	mov eax,1 						; Code for Exit Syscall
	mov ebx,0 						; Return a code of zero
	int 80H 						; Make kernel call



