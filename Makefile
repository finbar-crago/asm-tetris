all:
	nasm -f bin -o main.bin main.asm
	qemu-system-i386 -vga std main.bin
