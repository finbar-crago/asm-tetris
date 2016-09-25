	org  0x7c00
	bits 16

	xor ax, ax
	mov ax, cs
	mov ds, ax

	mov ax, 4F02h		; Set Display
	mov bx, 0112h		; VBE mode (640x480/24)
	int 10h

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


	mov eax, 0AA00h		; why???
	mov ebx, (640*480*4)	; size of fb (640x480x3)
.loop:
	mov [eax + 0], byte 0
	mov [eax + 1], byte 0
	mov [eax + 2], byte 255
	add eax, 3
	cmp eax, ebx
	jne .loop

	jmp $



	times 510 - ($-$$) db 0
	dw 0xaa55
