// VGA text mode constants
#define VGA_MEMORY ((unsigned char*)0xB8000)
#define VGA_WIDTH 80
#define VGA_HEIGHT 25

// Color codes (4 bits background, 4 bits foreground)
#define COLOR_BLACK 0
#define COLOR_LIGHT_GRAY 7
#define COLOR_LIGHT_GREEN 10
#define COLOR_LIGHT_CYAN 11
#define COLOR_YELLOW 14
#define COLOR_WHITE 15

// Create color byte from foreground and background
#define MAKE_COLOR(fg, bg) ((bg << 4) | fg)

// Current cursor position
static int cursor_x = 0;
static int cursor_y = 0;
static unsigned char current_color = MAKE_COLOR(COLOR_LIGHT_GRAY, COLOR_BLACK);

// ===== Terminal functions ===== 
void terminal_setcolor(unsigned char color) {
    current_color = color;
}

void terminal_putchar(char c) {
    // Handle special characters
    if (c == '\n') {
        cursor_x = 0;
        cursor_y++;
    } else if (c == '\r') {
        cursor_x = 0;
    } else if (c == '\t') {
        cursor_x = (cursor_x + 4) & ~(4 - 1);
    } else {
        // Calculate position in VGA buffer
        int pos = (cursor_y * VGA_WIDTH + cursor_x) * 2;

        // Write character and color
        VGA_MEMORY[pos] = c;
        VGA_MEMORY[pos + 1] = current_color;

        cursor_x++;
    }

    // Handle line wrapping
    if (cursor_x >= VGA_WIDTH) {
        cursor_x = 0;
        cursor_y++;
    }

    // Handle scrolling (simple version - just wrap to top)
    if (cursor_y >= VGA_HEIGHT) {
        cursor_y = 0;
    }
}

void terminal_writestring(const char* str) {
    for (int i = 0; str[i] != '\0'; i++) {
        terminal_putchar(str[i]);
    }
}

// ===== Kernel Main =====
void kernel_main(void) {
    // Welcome message
    terminal_setcolor(MAKE_COLOR(COLOR_LIGHT_CYAN, COLOR_BLACK));
    terminal_writestring("SimpleOS Kernel\n");

    terminal_setcolor(MAKE_COLOR(COLOR_YELLOW, COLOR_BLACK));
    terminal_writestring("Version 0.1 - Day 4\n\n");

    terminal_setcolor(MAKE_COLOR(COLOR_WHITE, COLOR_BLACK));
    terminal_writestring("Successfully entered C code!\n\n");

    // System info
    terminal_setcolor(MAKE_COLOR(COLOR_LIGHT_GREEN, COLOR_BLACK));
    terminal_writestring("[OK] ");
    terminal_setcolor(MAKE_COLOR(COLOR_WHITE, COLOR_BLACK));
    terminal_writestring("64-bit long mode active\n");

    terminal_setcolor(MAKE_COLOR(COLOR_LIGHT_GREEN, COLOR_BLACK));
    terminal_writestring("[OK] ");
    terminal_setcolor(MAKE_COLOR(COLOR_WHITE, COLOR_BLACK));
    terminal_writestring("C kernel initialized\n");

    // Inifinite loop - kernel should never return
    while (1) {
        __asm__ volatile("hlt");
    }
    
}