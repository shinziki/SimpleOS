// VGA text mode constants
#define VGA_MEMORY (unsigned char*)0xB8000
#define VGA_WIDTH 80
#define VGA_HEIGHT 25

// Color codes (4 bits background, 4 bits foreground)
#define COLOR_BLACK 0
#define COLOR_LIGHT_GRAY 7
#define COLOR_LIGHT_CYAN 11

// Create color byte from foreground and background
#define MAKE_COLOR(fg, bg) ((bg << 4) | fg)

// Current cursor position
static unsigned char current_color = MAKE_COLOR(COLOR_LIGHT_GRAY, COLOR_BLACK);

// ===== Terminal functions ===== 
void terminal_setcolor(unsigned char color) {
    current_color = color;
}

// ===== Kernel Main =====
void kernel_main(void) {
    // Welcome message
    terminal_setcolor(MAKE_COLOR(COLOR_LIGHT_CYAN, COLOR_BLACK));

    // Inifinite loop - kernel should never return
    while (1) {
        __asm__ volatile("hlt");
    }
    
}