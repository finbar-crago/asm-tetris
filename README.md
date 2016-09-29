# Tetris in x86 assembly

## Protected Mode
```nasm
cli           ; Disable Interrupts
lgdt [gdtr]   ; Load GDR

in  al, 0x93  ; Switch A20 gate
or  al, 2
and al,~1
out 0x92, al

mov eax, cr0  ; Enable Protected Mode
or  eax, 1
mov cr0, eax

jmp 0x08:Main
```
#### Reference
+ http://kurser.iha.dk/eit/embedded/Artikler/Gareau/Protected-Mode.pdf
+ http://ladsoft.tripod.com/pmode/masm386.txt
+ http://www.independent-software.com/writing-your-own-bootloader-for-a-toy-operating-system-7/
+ http://blog.ackx.net/asm-hello-world-bootloader.html
+ http://stackoverflow.com/questions/9137947/assembler-jump-in-protected-mode-with-gdt

### Global Descriptor Table
```nasm
        ;; Global Descriptor Table (GDT)
gdt:    dq 0x0000000000000000 ; null
        dq 0x00cf9a000000ffff ; code
        dq 0x00cf92000000ffff ; data

gdtr:   dw  gdtr - gdt - 1
        dd  gdt
```
#### Reference
+ http://wiki.osdev.org/Global_Descriptor_Table
+ http://f.osdev.org/viewtopic.php?f=1&t=28936&start=15
+ http://skelix.net/skelixos/tutorial02_en.html

## Display
### VESA
```nasm
mov ax, 4F01h          ; Get VBE Info
mov cx, (0x115|0x4000) ; Mode (or 0x4000 for LFB)
mov di, vbe_info       ; ptr to 256 byte block
int 10h

mov edi, dword [vbe_info+28h]
mov [fbPtr], edi       ; Save LFB ptr

mov ax, 4F02h          ; Set VBE Mode
mov bx, (0x115|0x4000)
int 10h
```
#### Reference
+ http://www.petesqbsite.com/sections/tutorials/tuts/vbe3.pdf
+ https://forum.nasm.us/index.php?topic=963.0
+ http://computer-programming-forum.com/45-asm/10bd8847d74ce261-2.htm
+ http://stackoverflow.com/questions/16997250/bochs-with-graphics
+ http://www.monstersoft.com/tutorial1/VESA_info.html
+ http://www.asmcommunity.net/forums/topic/?id=10733
+ http://bos.asmhackers.net/docs/vga_without_bios/snippet_5/vga.php

## Misc
### NASM
+ http://www.nasm.us/doc/nasmdoc3.html
