	BITS 16
	ORG 0x7C00
	
	KB_INT EQU 9
	
start:
	mov ax, 09000h		; Set 64K-1 Stack at 09000h.
	mov ss, ax
	mov sp, 0ffffh

	mov ax, 07C0h		; Set data segment to where we're loaded
	mov ds, ax
	
	cli
	push word 0
	pop ds
	mov [4 * KB_INT], word kbdEvent
	mov [4 * KB_INT + 2], cs
	sti



	
	mov ah, 00h		; Set grapics to VGA
	mov al, 13h		; (12h: 640x480,16; 13h: 320x200,256)
	int 10h

	mov ax, 0Bh		; Set text light blue
	mov bl, 09h
	int 10h

;	mov si, text_string	; Put string position into SI
;	call print_string	; Call our string-printing routine

	
	mov byte [bg_colour],42h
.loop:
;	inc byte [bg_colour]
	call setbg
	call tick
	call tick
	call tick
	jmp .loop


	
	jmp $			; Jump here - infinite loop!

	text_string db 'This is a TEST!', 0xa,0xd, 0
	bg_colour db 0

setbg:
	mov ax,0A000h
	mov es,ax		; start of fb mem
	mov di,0h		; START ???
	mov al,[bg_colour]
	mov cx,64000  		; Size of fb
	rep stosb
	ret

	
print_string:			; Routine: output string in SI to screen
	mov ah, 0Eh
	mov cx, 03h
.loop:
	lodsb			; Get char
	cmp al, 0
	je .done		; return if null
	int 10h			; print it
	jmp .loop
.done:
	ret


tick:				; see http://stackoverflow.com/questions/9971405
	pusha			;     http://stackoverflow.com/questions/17385356/

	mov ax, 0
	mov ds, ax
	mov bx, [46Ch]
.loop:
	mov ax, [46Ch]
	cmp ax, bx
	je   .loop

	popa
	ret

	
; see http://inglorion.net/documents/tutorials/x86ostut/keyboard/
;     https://github.com/dbittman/bootris/blob/master/bootris.s
kbdEvent:			
	pusha
	in al, 60h
	test al, 80h
	jnz .end

	mov cx, 1		
	mov ah, 0x0A
	int 0x10
	
	inc byte [bg_colour]

.end:
	mov al, 20h
	out 20h, al
	popa
	iret


	
	times 510-($-$$) db 0	; Pad remainder of boot sector with 0s
	dw 0xAA55		; The standard PC boot signature

	
