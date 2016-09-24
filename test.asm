	BITS 16
	ORG 0x7C00

start:
	mov ax, 09000h		; Set 64K-1 Stack at 09000h
	mov ss, ax
	mov sp, 0ffffh

	mov ax, 07C0h		; set data segment
	mov ds, ax
	
	cli
	push word 0
	pop ds
	mov [4 * KB_INT], word kbdEvent ; set keyboard interrupt
	mov [4 * KB_INT + 2], cs
	sti

	
	mov ah, 00h		; set grapics to VGA
	mov al, 13h		; (12h: 640x480,16; 13h: 320x200,256)
	int 10h

	
	mov byte [bg_colour],42h
.loop:
;	inc byte [bg_colour]
	call setbg
	call tick
	call tick
	call tick
	jmp .loop


	jmp $			; looooooop!

	;; --- END OF MAIN PROGRAM ---


	;; vars, ptrs, etc...
	bg_colour db 0
	KB_INT EQU 9


	;; --- START FUNCTIONS ---


	;; set background colour function
setbg:
	mov ax,0A000h
	mov es,ax		; start of fb mem
	mov di,0h		; START ???
	mov al,[bg_colour]
	mov cx,64000  		; Size of fb
	rep stosb
	ret


	;; "tick" timing function
	;;
	;; ref: http://stackoverflow.com/questions/9971405/
	;;      http://stackoverflow.com/questions/17385356/
tick:
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

	
	;; keyboard interrupt function...
	;;
	;; ref: https://github.com/dbittman/bootris/blob/master/bootris.s
	;;      http://inglorion.net/documents/tutorials/x86ostut/keyboard/
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


	;; ---- END OF IMAGE ---
	times 510-($-$$) db 0	; Pad with 0
	dw 0xAA55		; boot signature
