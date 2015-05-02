video_buffer: vidbuff1.o
	ld -m elf_i386 -o video_buffer vidbuff1.o
vidbuff1.o: vidbuff1.asm
	nasm -f elf -g -F stabs vidbuff1.asm -l video_buffer.lst
	
	

