	org  0x7c00
	bits 16

	jmp Start

	;; Variables, etc...
	fbPtr dd 0
	vbe_info times 0x100 db 0

	;; Global Descriptor Table (GDT)
gdt:	dq 0x0000000000000000 ; null
	dq 0x00cf9a000000ffff ; code
	dq 0x00cf92000000ffff ; data

gdtr:	dw  gdtr - gdt - 1
	dd  gdt


Start:
	xor ax, ax
	mov ax, cs
	mov ds, ax

	;; Setup Display...
	mov ax, 4F01h		; Get VBE Info
	mov cx, (0x115|0x4000)	; VBE mode 0x115 (800x600/24)
	mov di, vbe_info
	int 10h
	cmp ax,0x004f		; hang on fail
	jnz $

	mov edi, dword [vbe_info+28h]
	mov [fbPtr], edi
	xor eax, eax
	mov es, ax

	mov ax, 4F02h		; Set Display
	mov bx, (0x115|0x4000)
	int 10h
	cmp ax,0x004f		; hang on fail
	jnz $

	;; Prep for 32 Bits
	cli			; Disable Interrupts 
	lgdt [gdtr]		; Load GDR

	in  al, 0x93         	; Switch A20 gate via fast A20 port 92
	or  al, 2
	and al, ~1
	out 0x92, al

	mov eax, cr0		; Enable Protected Mode
	or  eax, 1
	mov cr0, eax

	jmp 0x08:Main

	;; --- Start of Protected Mode ---
	bits 32
Main:
	mov eax, 0x10		; refresh all segment registers
	mov ds, eax
	mov es, eax
	mov fs, eax
	mov gs, eax
	mov ss, eax
	mov esp, 0x9000		; set a stack pointer

	mov al, 255
	mov edi, [fbPtr]
	mov ecx, (800*600*3)
	rep stosb

	mov eax, [fbPtr]
	push eax
	push (800*600)
	push 0xff0000
	call Fill

	add eax, (800*600)
	push eax
	push (800*600)
	push 0x00ff00
	call Fill

	add eax, (800*600)
	push eax
	push (800*600)
	push 0x0000ff
	call Fill

	jmp $			; Looooop for all future time; for always.....


	;; --- Start of Functions ---

Fill:
	push eax		; save state
	push ebx
	push ecx		; add 4 to esp for each push to find last arg

	mov eax, [esp+24]	; arg1 (start)
	mov ebx, eax
	add ebx, [esp+20]	; arg2 (size)
	mov ecx, [esp+16]	; arg3 (colour)
.loop:
	mov [eax], ecx
	add eax, 3
	cmp eax, ebx
	jne .loop

	pop ecx			; restore and return
	pop ebx
	pop eax
	ret


	;; This is the end.
	times 510 - ($-$$) db 0
	dw 0xaa55
