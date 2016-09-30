	org  0x7c00
	bits 16

	jmp Start

	;; Variables, Constants, Macros, etc...
	VBE_MODE EQU  115h	; (0x115 => 800x600/24)
	WIDTH    EQU  800
	HEIGHT   EQU  600

%macro  SETINT 2
	mov eax,%2
	mov [500h+%1*8],ax
	mov word [500h+%1*8+2],0x8
	mov word [500h+%1*8+4],0x8E00
	shr eax,16
	mov [500h+%1*8+6],ax
%endmacro

	fbPtr dd 0
	vbe_info times 0x100 db 0

dap:
	db	10h		; size of DAP
	db	0		; unused
	dw	1		; sectors to read
	dw	Main		; destination address (0:7e00)
	dw	0		; page
	dw	1		; starting LBA
	dw	0		; upper part of 48 bit LBA

	;; Global Descriptor Table (GDT)
gdt:	dq 0x0000000000000000 ; null
	dq 0x00cf9a000000ffff ; code
	dq 0x00cf92000000ffff ; data

gdtr:	dw  gdtr - gdt - 1
	dd  gdt

idtr:
	dw (100h*8)-1
	dd 0500h


Start:
	xor ax, ax
	mov ax, cs
	mov ds, ax

	;; Fetch from ATA
	;; http://wiki.osdev.org/ATA_in_x86_RealMode_(BIOS)
	mov si, dap
	mov ah, 0x42
	mov dl, 0x80
	int 0x13
	jc $

	;; Setup Display...
	mov ax, 4F01h		; Get VBE Info
	mov cx, (VBE_MODE|0x4000)
	mov di, vbe_info
	int 10h
	cmp ax,0x004f		; hang on fail
	jnz $

	mov edi, dword [vbe_info+28h]
	mov [fbPtr], edi
	xor eax, eax
	mov es, ax

	mov ax, 4F02h		; Set Display
	mov bx, (VBE_MODE|0x4000)
	int 10h
	cmp ax,0x004f		; hang on fail
	jnz $

	mov al,  0
	mov edi, 500h
	mov ecx, 100h
	rep stosb		; Zero IDT

	SETINT 42, ClearFB

	;; Prep for 32 Bits
	cli			; Disable Interrupts 
	lgdt [gdtr]		; Set GDR
	lidt [idtr]		; Set IDT

	in  al, 0x93         	; Switch A20 gate via fast A20 port 92
	or  al, 2
	and al, ~1
	out 0x92, al

	mov eax, cr0		; Enable Protected Mode
	or  eax, 1
	mov cr0, eax

	mov ax, 10h
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

	jmp 0x8:Main

	;; Pad out the boot sector..
	times 510 - ($-$$) db 0
	dw 0xaa55		; magic number

	;; --- Start of Protected Mode ---
	SECTION pmode start=0x7e00 ; http://stackoverflow.com/questions/28645439/
	bits 32
Main:
	mov esp, 0x9000		; set a stack pointer

	; call ClearFB
	int 42

	mov eax, 0
	mov ecx, 0xff0000
	mov ebx, (WIDTH * HEIGHT * 3)
.loop:
	push eax
	add  eax, [fbPtr]
	push eax
	push (WIDTH * HEIGHT)
	push ecx
	call Fill
	pop edx
	pop edx
	pop edx

	ror ecx, 8		; Bitwise Rotate on Colour

	pop eax
	add eax, (WIDTH * HEIGHT)
	mov edx, 0
	div ebx			; (eax/ebx) => eax, remainder => edx
	mov eax, edx		; http://stackoverflow.com/questions/8021772

	jmp $
	call Tick
	jmp .loop


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


ClearFB:
	pusha
	mov al,  0xff
	mov edi, [fbPtr]
	mov ecx, (WIDTH * HEIGHT * 3)
	rep stosb
	popa
	ret


;;  "tick" timing function
;;
;;  ref: http://stackoverflow.com/questions/9971405/
;;       http://stackoverflow.com/questions/17385356/
Tick:
	pusha
	mov ax, 0
	mov ds, ax
	mov bx, [46Ch]
	.loop:
	mov ax, [46Ch]
	cmp ax, bx
	je   .loop

	popa
	ret


	times 200h - ($-$$) db 90 ; Pad image to 1kb
