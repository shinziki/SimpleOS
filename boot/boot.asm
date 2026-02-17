[BITS 16]           
[ORG 0x7C00]      

KERNEL_OFFSET equ 0x10000   ; Load kernel to 64KB mark

start:
    ; Initialize segment registers
    cli
    xor ax, ax      
    mov ds, ax      
    mov es, ax      
    mov ss, ax      
    mov sp, 0x7C00  

    ; Print initial message
    mov si, msg_loading
    call print_16

    ; Load kernel from disk
    call load_kernel      

    ; Enable A20 line (method: Fast A20 gate)
    call enable_a20

    ; Load GDT
    lgdt [gdt_descriptor]

    ; Enter protected mode
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; Far jump to flush CPU pipeline and enter 32-bit code
    jmp CODE_SEG:protected_mode_start

; ===== Load Kernel from Disk =====

load_kernel:
    mov bx, KERNEL_OFFSET   ; Destination address
    mov dh, 15              ; Load 15 sectors (adjust if kernel grows)
    mov dl, [BOOT_DRIVE]    ; Drive number saved by BIOS
    call disk_load
    ret

disk_load:
    ; Load DH sectors from drive DL into ES:BX
    push dx                 ; Save sector count

    mov ah, 0x02            ; BIOS read sector function
    mov al, dh              ; Number of sectors to read
    mov ch, 0x00            ; Cylinder 0
    mov dh, 0x00            ; Head 0
    mov cl, 0x02            ; Start from sector 2 (sector 1 is boot sector)

    int 0x13                ; BIOS disk interrupt
    jc disk_error           ; Jump if error (carry flag set)

    pop dx                  ; Restore sector count
    cmp al, dh              ; Check if all sectors read
    jne disk_error

    mov si, msg_loaded
    call print_16
    ret

disk_error:
    mov si, msg_disk_error
    call print_16
    jmp hang_16

; ===== 16-bit Functions =====

enable_a20:
    ; Fast A20 method - write to port 0x92
    in al, 0x92         
    or al, 2            
    out 0x92, al        
    ret

print_16:
    ; 16-bit print function (BIOS interrupt)
    mov ah, 0x0E
.loop:
    lodsb           
    test al, al     
    jz .done        
    int 0x10        
    jmp .loop       
.done:
    ret

hang_16:
    cli
    hlt
    jmp hang_16

; ===== GDT for 32-bit Protected Mode =====

gdt_start:

; Null descriptor (required by CPU)
.gdt_null:
    dd 0x0              
    dd 0x0              

; Code segment descriptor
gdt_code:
    dw 0xFFFF           
    dw 0x0              
    db 0x0              
    db 10011010b        
    db 11001111b        
    db 0x0              

; Data segment descriptor
gdt_data:
    dw 0xFFFF           
    dw 0x0              
    db 0x0              
    db 10010010b        
    db 11001111b        
    db 0x0              

gdt_end:

; GDT descriptor (tells CPU where GDT is)
gdt_descriptor:
    dw gdt_end - gdt_start - 1  
    dd gdt_start                

; Calculate segment selectors (offset from GDT start)
CODE_SEG equ gdt_code - gdt_start  
DATA_SEG equ gdt_data - gdt_start  

; ===== 32-bit Protected Mode Code =====

[BITS 32]               

protected_mode_start:
    ; Set up segment registers for protected mode
    mov ax, DATA_SEG    
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000    

    ; Now transition to long mode
    call setup_page_tables
    call enable_paging

    ; Load 64-bit GDT
    lgdt [gdt64_descriptor]

    ; Jump to 64-bit code
    jmp CODE_SEG64:long_mode_start

; ===== Page Table Setup =====

setup_page_tables:
    ; We'll identity map the first 2MB of memory
    ; This means virtual address = physical address

    ; Clear the page table area (4096 bytes each)
    mov edi, 0x1000
    mov cr3, edi
    xor eax, eax
    mov ecx, 4096
    rep stosd
    mov edi, cr3

    ; Build page tables
    ; PML4[0] -> PDPT
    mov DWORD [edi], 0x2003

    ; PDPT[0] -> PD
    mov DWORD [edi + 0x1000], 0x3003

    ; PD[0] -> 2MB page
    mov DWORD [edi + 0x2000], 0x0083

    ret

enable_paging:
    ; Enable PAE (Physical Address Extension)- required for long mode
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    ; Set LM (Long Mode) bit in EFER MSR
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    ; Enable paging
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax

    ret 

; ===== 64-bit GDT =====

gdt64_start:

gdt64_null:
    dq 0x0

gdt64_code:
    ; Code segment for 64-bit mode
    dw 0xFFFF
    dw 0x0              
    db 0x0              
    db 10011010b        
    db 10101111b        
    db 0x0  

gdt64_data:
    dw 0xFFFF           
    dw 0x0              
    db 0x0              
    db 10010010b        
    db 10101111b        
    db 0x0  

gdt64_end:

gdt64_descriptor:
    dw gdt64_end - gdt64_start - 1
    dd gdt64_start

CODE_SEG64 equ gdt64_code - gdt64_start  
DATA_SEG64 equ gdt64_data - gdt64_start

; ===== 64-bit Long Mode Code =====

[BITS 64]               

long_mode_start:
    ; Clear segment registers (not used in 64-bit mode the same way)
    mov ax, DATA_SEG64    
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax 

    ; Set up stack in 64-bit mode
    mov rsp, 0x90000

    ; Jump to kernel!
    call KERNEL_OFFSET

    ; If kernel returs, hang
hang:
    hlt             
    jmp hang                   

; ===== Data =====

BOOT_DRIVE: db 0                ; Will be set by BIOS

msg_loading: db 'Loading kernel...', 13, 10, 0
msg_loaded: db 'Kernel loaded!', 13, 10, 0
msg_disk_error: db 'Disk error!', 13, 10, 0

; Boot signature - BIOS requires bytes 510-511 to be 0xAA55
times 510-($-$$) db 0   
dw 0xAA55              