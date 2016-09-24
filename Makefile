all:
	nasm -f bin -o test.bin test.asm
	qemu-system-i386 test.bin

