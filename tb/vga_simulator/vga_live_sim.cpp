// =============================================================================
// File       : vga_live_sim.cpp
// Description: Live VGA Display Simulator for RISC-V SoC (640x480 @ 60 Hz)
// Adapted from Saman Mohseni's VGA Simulator with DPI-C & Multi-Mode Output
// =============================================================================

#include <iostream>
#include <fstream>
#include <vector>
#include <thread>
#include <mutex>
#include <atomic>
#include <chrono>
#include <cstring>
#include <cstdlib>

#include "vga_dpi.h"

// 640x480 @ 60 Hz VGA Standard Timings
static const int ACTIVE_WIDTH    = 640;
static const int ACTIVE_HEIGHT   = 480;
static const int H_FRONT_PORCH   = 16;
static const int H_SYNC_PULSE    = 96;
static const int H_BACK_PORCH    = 48;
static const int TOTAL_WIDTH     = 800;

static const int V_FRONT_PORCH   = 10;
static const int V_SYNC_PULSE    = 2;
static const int V_BACK_PORCH    = 33;
static const int TOTAL_HEIGHT    = 525;

// Framebuffers
static uint8_t g_render_buffer[ACTIVE_HEIGHT][ACTIVE_WIDTH][3] = {};
static uint8_t g_display_buffer[ACTIVE_HEIGHT][ACTIVE_WIDTH][3] = {};
static std::mutex g_buf_mutex;

// State tracking
static int g_coord_x = 0;
static int g_coord_y = 0;
static bool g_pre_hsync = true;
static bool g_pre_vsync = true;
static uint64_t g_pixel_tick = 0;
static uint32_t g_frame_count = 0;
static uint64_t g_active_pixel_count = 0;

static bool g_gui_enabled = false;
static std::atomic<bool> g_gl_ready{false};
static std::atomic<bool> g_running{true};

// Forward declaration of image writers
static void write_bmp(const std::string& filename, const uint8_t buffer[ACTIVE_HEIGHT][ACTIVE_WIDTH][3]);
static void write_ppm(const std::string& filename, const uint8_t buffer[ACTIVE_HEIGHT][ACTIVE_WIDTH][3]);

#if defined(ENABLE_VGA_OPENGL)
#include <GL/gl.h>
#include "freeglut/include/GL/freeglut.h"

static void gl_render() {
    glClear(GL_COLOR_BUFFER_BIT);
    {
        std::lock_guard<std::mutex> lock(g_buf_mutex);
        // Draw image using inverted Y raster for standard OpenGL coordinates
        glRasterPos2i(-1, 1);
        glPixelZoom(1.0f, -1.0f);
        glDrawPixels(ACTIVE_WIDTH, ACTIVE_HEIGHT, GL_RGB, GL_UNSIGNED_BYTE, g_display_buffer);
    }
    glutSwapBuffers();
}

static void gl_timer(int val) {
    if (!g_running) {
        glutLeaveMainLoop();
        return;
    }
    glutPostRedisplay();
    glutTimerFunc(16, gl_timer, 0); // ~60 FPS refresh
}

static void gl_keyboard(unsigned char key, int x, int y) {
    if (key == 27 || key == 'q' || key == 'Q') {
        std::cout << "[VGA-SIM] Exit requested via GUI window." << std::endl;
        g_running = false;
        glutLeaveMainLoop();
    } else if (key == 's' || key == 'S') {
        std::string snap = "vga_snapshot_frame" + std::to_string(g_frame_count) + ".bmp";
        std::lock_guard<std::mutex> lock(g_buf_mutex);
        write_bmp(snap, g_display_buffer);
        std::cout << "[VGA-SIM] Snapshot manually saved: " << snap << std::endl;
    }
}

static void run_gl_thread(int argc, char** argv) {
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB);
    glutInitWindowSize(ACTIVE_WIDTH, ACTIVE_HEIGHT);
    glutInitWindowPosition(80, 80);
    glutCreateWindow("RISC-V SoC VGA Live Simulator (640x480 @ 60Hz)");

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glutDisplayFunc(gl_render);
    glutKeyboardFunc(gl_keyboard);
    glutTimerFunc(16, gl_timer, 0);

    g_gl_ready = true;
    std::cout << "[VGA-SIM] OpenGL live display window active (640x480)." << std::endl;
    glutMainLoop();
    g_gl_ready = false;
}
#endif

// BMP File Exporter (24-bit uncompressed RGB)
static void write_bmp(const std::string& filename, const uint8_t buffer[ACTIVE_HEIGHT][ACTIVE_WIDTH][3]) {
    std::ofstream out(filename, std::ios::binary);
    if (!out) {
        std::cerr << "[VGA-SIM] Error creating BMP file: " << filename << std::endl;
        return;
    }

    uint32_t row_padded = (ACTIVE_WIDTH * 3 + 3) & (~3);
    uint32_t data_size  = row_padded * ACTIVE_HEIGHT;
    uint32_t file_size  = 54 + data_size;

    // Bitmap File Header (14 bytes)
    uint8_t file_header[14] = {
        'B', 'M',
        static_cast<uint8_t>(file_size),
        static_cast<uint8_t>(file_size >> 8),
        static_cast<uint8_t>(file_size >> 16),
        static_cast<uint8_t>(file_size >> 24),
        0, 0, 0, 0,
        54, 0, 0, 0
    };

    // DIB Header (40 bytes - BITMAPINFOHEADER)
    uint8_t info_header[40] = {
        40, 0, 0, 0,
        static_cast<uint8_t>(ACTIVE_WIDTH),
        static_cast<uint8_t>(ACTIVE_WIDTH >> 8),
        static_cast<uint8_t>(ACTIVE_WIDTH >> 16),
        static_cast<uint8_t>(ACTIVE_WIDTH >> 24),
        static_cast<uint8_t>(ACTIVE_HEIGHT),
        static_cast<uint8_t>(ACTIVE_HEIGHT >> 8),
        static_cast<uint8_t>(ACTIVE_HEIGHT >> 16),
        static_cast<uint8_t>(ACTIVE_HEIGHT >> 24),
        1, 0,
        24, 0,
        0, 0, 0, 0,
        static_cast<uint8_t>(data_size),
        static_cast<uint8_t>(data_size >> 8),
        static_cast<uint8_t>(data_size >> 16),
        static_cast<uint8_t>(data_size >> 24),
        0x13, 0x0B, 0, 0, // 2835 pixels/meter
        0x13, 0x0B, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0
    };

    out.write(reinterpret_cast<const char*>(file_header), 14);
    out.write(reinterpret_cast<const char*>(info_header), 40);

    std::vector<uint8_t> pad(row_padded - ACTIVE_WIDTH * 3, 0);

    // Write pixel rows bottom-to-top (standard BMP format)
    for (int y = ACTIVE_HEIGHT - 1; y >= 0; --y) {
        for (int x = 0; x < ACTIVE_WIDTH; ++x) {
            uint8_t b = buffer[y][x][2];
            uint8_t g = buffer[y][x][1];
            uint8_t r = buffer[y][x][0];
            out.put(b);
            out.put(g);
            out.put(r);
        }
        if (!pad.empty()) {
            out.write(reinterpret_cast<const char*>(pad.data()), pad.size());
        }
    }
}

// PPM File Exporter (Portable Pixel Map P6)
static void write_ppm(const std::string& filename, const uint8_t buffer[ACTIVE_HEIGHT][ACTIVE_WIDTH][3]) {
    std::ofstream out(filename, std::ios::binary);
    if (!out) return;

    out << "P6\n" << ACTIVE_WIDTH << " " << ACTIVE_HEIGHT << "\n255\n";
    out.write(reinterpret_cast<const char*>(buffer), ACTIVE_WIDTH * ACTIVE_HEIGHT * 3);
}

extern "C" void vga_dpi_init() {
    std::cout << "==========================================================" << std::endl;
    std::cout << "  VGA Live Simulation Monitor Initialized (640x480@60Hz)"   << std::endl;
    std::cout << "==========================================================" << std::endl;

    const char* disp = std::getenv("DISPLAY");
    const char* env_gui = std::getenv("VGA_GUI");
    bool want_gui = (env_gui != nullptr && (std::string(env_gui) == "1" || std::string(env_gui) == "true"));

#if defined(ENABLE_VGA_OPENGL)
    if (disp != nullptr && strlen(disp) > 0 && want_gui) {
        g_gui_enabled = true;
        static int argc = 1;
        static char arg0[] = "vga_sim";
        static char* argv[] = { arg0, nullptr };
        std::thread(run_gl_thread, argc, argv).detach();
        while (!g_gl_ready) {
            std::this_thread::sleep_for(std::chrono::milliseconds(5));
        }
    } else {
        std::cout << "[VGA-SIM] Running in headless/frame-capture mode." << std::endl;
        std::cout << "          (Set VGA_GUI=1 with valid DISPLAY to enable live GUI)" << std::endl;
    }
#else
    std::cout << "[VGA-SIM] Running high-speed frame capture mode (PPM/BMP output)." << std::endl;
#endif
}

extern "C" void vga_dpi_sample(
    unsigned char hsync,
    unsigned char vsync,
    unsigned char r,
    unsigned char g,
    unsigned char b
) {
    g_pixel_tick++;
    g_coord_x = (g_coord_x + 1) % TOTAL_WIDTH;

    // Resynchronize on falling edge of HSYNC (start of active sync pulse)
    if (!hsync && g_pre_hsync) {
        g_coord_x = ACTIVE_WIDTH + H_FRONT_PORCH;
        g_coord_y = (g_coord_y + 1) % TOTAL_HEIGHT;
    }

    // Resynchronize on falling edge of VSYNC (end of active frame scan)
    if (!vsync && g_pre_vsync) {
        g_coord_y = ACTIVE_HEIGHT + V_FRONT_PORCH;

        // Frame completed!
        g_frame_count++;
        {
            std::lock_guard<std::mutex> lock(g_buf_mutex);
            std::memcpy(g_display_buffer, g_render_buffer, sizeof(g_render_buffer));
        }

        // Output current live frame to disk
        write_bmp("vga_live_frame.bmp", g_render_buffer);
        write_ppm("vga_live_frame.ppm", g_render_buffer);

        std::cout << "[VGA-SIM] Frame #" << g_frame_count
                  << " rendered (" << g_active_pixel_count << " active pixels)."
                  << " Saved: vga_live_frame.bmp" << std::endl;

        g_active_pixel_count = 0;
    }

    // Sample active video area (0..639, 0..479)
    if (g_coord_x < ACTIVE_WIDTH && g_coord_y < ACTIVE_HEIGHT) {
        // Expand 4-bit color [0..15] to 8-bit [0..255]
        uint8_t r8 = static_cast<uint8_t>(r * 17);
        uint8_t g8 = static_cast<uint8_t>(g * 17);
        uint8_t b8 = static_cast<uint8_t>(b * 17);

        g_render_buffer[g_coord_y][g_coord_x][0] = r8;
        g_render_buffer[g_coord_y][g_coord_x][1] = g8;
        g_render_buffer[g_coord_y][g_coord_x][2] = b8;

        if (r != 0 || g != 0 || b != 0) {
            g_active_pixel_count++;
        }
    }

    g_pre_hsync = (hsync != 0);
    g_pre_vsync = (vsync != 0);
}

extern "C" void vga_dpi_finish() {
    std::cout << "==========================================================" << std::endl;
    std::cout << "  VGA Simulation Finished: " << g_frame_count << " full frames captured." << std::endl;
    std::cout << "  Final Live Frame: vga_live_frame.bmp / vga_live_frame.ppm" << std::endl;
    std::cout << "==========================================================" << std::endl;

    // Flush final frame
    write_bmp("vga_live_frame.bmp", g_render_buffer);
    write_ppm("vga_live_frame.ppm", g_render_buffer);
    g_running = false;
}
