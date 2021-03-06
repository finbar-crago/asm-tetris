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

	;; Global Variables
	tick dd 0
	fbPtr dd 0
	ink dd 0

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

	;; PIC/IRQ Interrupt Stuff...
	;; http://forum.osdev.org/viewtopic.php?f=1&p=247999
	;; https://courses.engr.illinois.edu/ece390/books/artofasm/CH17/CH17-3.html
	mov al,0x11		; put both 8259s to init mode
	out 0x20,al
	out 0xA0,al

	mov al,0x20		; remap pic irq0-irq7 -> int 20h-27h
	out 0x21,al

	in  al, 21h
	and al, 0xfc		; Enable IRQ 0 & 1
	out 21h, al		; Write to PIC1

	in  al, 0a1h
	mov al, 0xff		; Enable nothing
	out 0xa1, al		; Write to PIC2

	SETINT 20h, tickInt
;	SETINT 21h, kbdInt
	SETINT 21h, nullInt

	;; Set IRQ0 timer to 10ms
	;; http://www.brokenthorn.com/Resources/OSDevPit.html
	mov  al, 110110b
	out  0x43, al
	mov  ax, 1193180/100	; 100hz/10ms
	out  0x40, al
	xchg ah, al
	out  0x40, al

	sti			; interrupts on

	;; --- Start Application Code ---
	mov dword [ink], 0__ff_ff_00_h

	mov ebx, 0h
.loop:
	push ebx		; [ebp + 20] x
	push 00h		; [ebp + 16] y
	push 10h		; [ebp + 12] x+i
	push 10h		; [ebp +  8] y+i

	call DrawBox
	inc dword [ink]

	mov eax, 1
	call Sleep
	inc ebx
	jmp .loop

	jmp $			; Looooop for all future time.....

	;; --- Start of Functions ---

DrawBox:
	push ebp
	mov ebp, esp
	sub esp, (4*4)

	push eax
	push ebx
	push ecx

	mov eax, [ebp + 20]	; x
	mov ebx, 3
	mul ebx
	mov [ebp + 20], eax

	mov eax, [ebp + 12]	; y
	mov ebx, 3
	mul ebx
	mov [ebp + 12], eax

	mov ebx, [ebp + 8]	; y+i
.loop:
	mov edi, (WIDTH*3)
	mov eax, [ebp + 16]	; x+i
	add eax, ebx
	mul edi
	mov edi, [fbPtr]
	add edi, eax
	add edi, [ebp + 20]	; x

	mov al,  [ink]
	mov ecx, [ebp + 12]	; x+i
	rep stosb

	dec ebx
	jnz .loop

	pop ecx
	pop ebx
	pop eax

	mov esp, ebp
	pop ebp
	ret (4*4)


ClearFB:
	pusha
	mov al,  0xff
	mov edi, [fbPtr]
	mov ecx, (WIDTH * HEIGHT * 3)
	rep stosb
	popa
	ret


	;; Sleep
	;; EAX => ticks to wait (1 tick == 10ms)
Sleep:
	push ebx
.loop0:
	mov ebx, dword [tick]
	inc ebx
	jno .loop1
	inc ebx
.loop1:
	cmp dword [tick], ebx
	jb .loop1

	dec eax
	jnz .loop0
	pop ebx
	ret


kbdInt:
	push eax
	in al,60h		; read from keyboard

	call ClearFB

	mov al,20h		; acknowledge the interrupt
	out 20h,al
	pop eax
	iret


tickInt:
	cli
	push eax
	inc dword [tick]
	mov al,20h
	out 20h,al
	pop eax
	sti
	iret


nullInt:
	mov al,20h
	out 20h,al
	iret

	;; --- End of the image. ---
	times 200h - ($-$$) db 0 ; Pad image to 1kb
