all:
	nasm -f bin -o main.bin boot.asm
	qemu-system-i386 main.bin

