# Assemble and compiler
ASM = nasm
CC = x86_64-elf-gcc
LD = x86_64-elf-ld

# Flags
ASMFLAGS = -f elf64
CFLAGS = -m64 -ffreestanding -fno-pie -fno-stack-protector -mno-red-zone -c
LDFLAGS = -T linker.ld

# Output files
BOOTLOADER = boot.bin
KERNEL = kernel.bin
OS_IMAGE = simpleos.bin

# Source files
BOOT_SRC = boot/boot.asm
KERNEL_ENTRY_SRC = kernel/kernel_entry.asm
KERNEL_C_SRC = kernel/kernel.c

# Object files
KERNEL_ENTRY_OBJ = kernel_entry.o
KERNEL_C_OBJ = kernel.o

.PHONY: all clean run

all: $(OS_IMAGE)

# Build bootloader(flat binary)
$(BOOTLOADER): $(BOOT_SRC)
	$(ASM) -f bin $(BOOT_SRC) -o $(BOOTLOADER)

# Build kernel entry (ELF object)
$(KERNEL_ENTRY_OBJ): $(KERNEL_ENTRY_SRC)
	$(ASM) $(ASMFLAGS) $(KERNEL_ENTRY_SRC) -o $(KERNEL_ENTRY_OBJ)

# Build kernel C code (ELF object)
$(KERNEL_C_OBJ): $(KERNEL_C_SRC)
	$(CC) $(CFLAGS) $(KERNEL_C_SRC) -o $(KERNEL_C_OBJ)

# Link kernel objects into kernel binary
$(KERNEL): $(KERNEL_ENTRY_OBJ) $(KERNEL_C_OBJ)
	$(LD) $(LDFLAGS) $(KERNEL_ENTRY_OBJ) $(KERNEL_C_OBJ) -o $(KERNEL)

# Concatenate bootloader and kernel
$(OS_IMAGE): $(BOOTLOADER) $(KERNEL)
	cat $(BOOTLOADER) $(KERNEL) > $(OS_IMAGE)

# Run in QEMU
run: $(OS_IMAGE)
	qemu-system-x86_64 -drive format=raw,file=$(OS_IMAGE)

# Clean build artifacts
clean:
	rm -f $(BOOTLOADER) $(KERNEL) $(OS_IMAGE) $(KERNEL_ENTRY_OBJ) $(KERNEL_C_OBJ)