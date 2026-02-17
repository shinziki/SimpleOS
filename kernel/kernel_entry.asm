[BITS 64]
[EXTERN kernel_main]        ; kernel_main is defined in kernel.c

global _start               ; Make _start visible to linker

_start:
    ; Clear the screen first
    call clear_screen

    ; Call the C kernel
    call kernel_main

    ; If kernel_main returns, hang forever
hang:
    cli
    hlt
    jmp hang

; Clear screen function
clear_screen:
    mov rdi, 0xB8000        ; VGA buffer
    mov rcx, 2000           ; 80x25 characters
    mov ax, 0x0F20          ; Space character with white on black
    rep stosw               ; Store AX to [RDI], RCX times
    ret