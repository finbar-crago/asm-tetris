	org  0x7c00
	bits 16

	xor ax, ax
	mov ax, cs
	mov ds, ax

	;; Display Setup...
	;; https://forum.nasm.us/index.php?topic=963.0
	;; http://computer-programming-forum.com/45-asm/10bd8847d74ce261-2.htm
	mov ax, 4F01h		; Get VBE Info
	mov cx, 0x115		; VBE mode (0x112: 640x480/24, 0x115: 800x600/24)
	or  cx, 0x4000		; http://stackoverflow.com/questions/16997250/bochs-with-graphics
	mov di, vbe_info
	int 10h
	cmp ax,0x004f		; hang on fail
	jnz $

	mov edi, dword [es:di+28h]
	mov [fbPtr], edi
	xor eax, eax
	mov es, ax
	;; ?? http://www.monstersoft.com/tutorial1/VESA_info.html
	;; ?? http://www.asmcommunity.net/forums/topic/?id=10733&page=2

	mov ax, 4F02h		; Set Display
	mov bx, 0x115
	or  bx, 0x4000
	int 10h
	cmp ax,0x004f		; hang on fail
	jnz $


	;; Prep for 32 Bits
	cli			; Disable Interrupts 
	lgdt [gdtr]		; Load GDR

	in al, 0x93         	; Switch A20 gate via fast A20 port 92
	or al, 2
	and al, ~1
	out 0x92, al

	mov eax, cr0		; Enable Protected Mode
	or eax, 1
	mov cr0, eax

	jmp 0x08:Main

	;; global descriptor table (gdt)
	;; http://f.osdev.org/viewtopic.php?f=1&t=28936&start=15
gdt:	dw  0x0000, 0x0000, 0x0000, 0x0000 ; null
	dw  0xFFFF, 0x0000, 0x9800, 0x00CF ; code
	dw  0xFFFF, 0x0000, 0x9200, 0x00CF ; data
gdtr:	dw  gdtr - gdt - 1
	dd  gdt

	;; Protected Mode
	bits 32
Main:
	mov     eax, 0x10 	; refresh all segment registers
	mov     ds, eax
	mov     es, eax
	mov     fs, eax
	mov     gs, eax
	mov     ss, eax


	mov al, 255
	mov edi, fbPtr
	mov ecx, (800*600*3)
	rep stosb

	mov eax, fbPtr
	mov ebx, eax
	add ebx, (800*600*3)
.loop:
	mov [eax + 0], byte 0
	mov [eax + 1], byte 0
	mov [eax + 2], byte 255
	add eax, 3
	cmp eax, ebx
	jne .loop


	jmp $

	fbPtr dd 0
	vbe_info times 40h db 0

	times 510 - ($-$$) db 0
	dw 0xaa55
