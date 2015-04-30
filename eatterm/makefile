cursor_control: cursor_2.o
	ld -m elf_i386 -o cursor_control cursor_2.o
cursor_2.o: cursor_2.asm
	nasm -f elf -g -F stabs cursor_2.asm -l cursor_control.lst
	
	

