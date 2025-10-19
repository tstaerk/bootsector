; boot_heartY.asm — Boot sector: print text, then redefine 'Y' to a heart (8x16)
; Assemble: nasm -f bin boot_heartY.asm -o boot_heartY.img

BITS 16
ORG 0x7C00

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    ; DS = CS so we can read our data
    push cs
    pop  ds

    ; Ensure classic 80x25 text mode (8x16 font)
    mov ax, 0x0003
    int 0x10

    ; Print the line with normal ROM 'Y' first
    mov si, msg
    call print_string

    ; --- Load custom glyph for 'Y' (0x59) into font block 0 and activate it ---
    cld
    push cs
    pop  es
    mov  bp, heartY      ; ES:BP -> 16 bytes (8x16 bitmap)
    mov  ax, 0x1100      ; INT 10h, AH=11h, AL=00h: Load user-defined chars
    mov  bh, 16          ; height = 16 scanlines
    mov  bl, 0           ; font block 0
    mov  cx, 1           ; count = 1 character
    mov  dx, 0x0059      ; starting code = 'Y'
    int  0x10

    mov  ax, 0x1103      ; INT 10h, AH=11h, AL=03h: Select active font block
    mov  bl, 0           ; activate block 0 we just loaded
    int  0x10

.hang:
    hlt
    jmp .hang

; --- Subroutines -------------------------------------------------------------

print_string:
    lodsb                 ; AL <- [DS:SI], SI += 1
    test al, al
    jz   .done
    mov  ah, 0x0E         ; BIOS teletype (TTY)
    mov  bh, 0x00
    mov  bl, 0x07         ; light gray on black
    int  0x10
    jmp  print_string
.done:
    ret

; --- Data -------------------------------------------------------------------

msg db 'Welcome from the bootsector YYY', 0

; 8x16 heart bitmap for 'Y' (each byte = 1 row, bit7=leftmost pixel)
; Tweak to taste; centered for 8-pixel width.
heartY:
    db 00000000b ; 0
    db 01100110b ; 1   **  **
    db 11111111b ; 2  ********
    db 11111111b ; 3  ********
    db 11111111b ; 4  ********
    db 01111110b ; 5   ******
    db 00111100b ; 6    ****
    db 00011000b ; 7     **
    db 00011000b ; 8     **
    db 00011000b ; 9     **
    db 00011000b ; 10    **
    db 00011000b ; 11    **
    db 00000000b ; 12
    db 00000000b ; 13
    db 00000000b ; 14
    db 00000000b ; 15

; --- Boot signature (must be last 2 bytes of the first 512 bytes) -----------
times 510-($-$$) db 0
dw 0xAA55
