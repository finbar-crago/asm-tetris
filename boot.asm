	org  0x7c00
	bits 16

	xor ax, ax
	mov ax, cs
	mov ds, ax

	;; Display Setup...
	;; https://forum.nasm.us/index.php?topic=963.0
	;; http://computer-programming-forum.com/45-asm/10bd8847d74ce261-2.htm
	mov ax, 4F01h		; Get VBE Info
	mov bx, 0112h		; VBE mode (640x480/24)
	mov di, vbe_info
	int 10h

	mov ax, 4F02h		; Set Display
	mov bx, 0112h		; VBE mode (640x480/24)
	int 10h

	mov di,vbe_info
	mov edi, dword [es:di+28h]
	xor eax,eax
	mov es,ax
	mov [fb],edi

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

	jmp (CODE_DESC - NULL_DESC) : Main

	;; Global Descriptor Table (GDT)
	;; http://f.osdev.org/viewtopic.php?f=1&t=28936&start=15
NULL_DESC:
	dd 0            	; null descriptor
	dd 0

CODE_DESC:
	dw 0xFFFF       	; limit low
	dw 0            	; base low
	db 0            	; base middle
	db 10011010b    	; access
	db 11001111b    	; granularity
	db 0            	; base high

DATA_DESC:
	dw 0xFFFF       	; data descriptor
	dw 0            	; limit low
	db 0            	; base low
	db 10010010b    	; access
	db 11001111b    	; granularity
	db 0            	; base high

gdtr:
	dw gdtr - NULL_DESC - 1
	dd NULL_DESC

	;; Protected Mode
	bits 32
Main:
	mov     ax, DATA_DESC - NULL_DESC
	mov     ds, ax		; update data segment


	mov eax, fb
	mov ebx, (640*480)	; size of fb (640x480x3)
.loop:
	mov [eax + 0], byte 0
	mov [eax + 1], byte 0
	mov [eax + 2], byte 255
	add eax, 3
	cmp eax, ebx
	jne .loop

	jmp $


	vbe_info resb 40h
	fb dd 0

	times 510 - ($-$$) db 0
	dw 0xaa55
