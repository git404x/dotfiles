#include "procedural.h"

static inline uint32_t fast_rand(uint32_t *state) {
    *state ^= *state << 13;
    *state ^= *state >> 17;
    *state ^= *state << 5;
    return *state;
}

/* privacy frame with subtle sensor floor noise to bypass blockage detection */
void procedural_render_privacy(uint8_t *buf, int width, int height, uint32_t frame) {
    uint32_t rng = 0x12345678 ^ frame;
    size_t total_pixels = (size_t)width * height;
    size_t macro_blocks = total_pixels / 2;

    for (size_t i = 0; i < macro_blocks; i++) {
        uint32_t r = fast_rand(&rng);
        /* sensor dark current fluctuation around 16 */
        int noise1 = (int)(r & 0x0F) - 7;
        int noise2 = (int)((r >> 8) & 0x0F) - 7;
        int noise_u = (int)((r >> 16) & 0x07) - 3;
        int noise_v = (int)((r >> 24) & 0x07) - 3;

        int y0 = 18 + noise1;
        int y1 = 18 + noise2;
        int u  = 128 + noise_u;
        int v  = 128 + noise_v;

        buf[i * 4 + 0] = (uint8_t)(y0 < 10 ? 10 : (y0 > 32 ? 32 : y0));
        buf[i * 4 + 1] = (uint8_t)u;
        buf[i * 4 + 2] = (uint8_t)(y1 < 10 ? 10 : (y1 > 32 ? 32 : y1));
        buf[i * 4 + 3] = (uint8_t)v;
    }
}

/* pure blackout frame in yuyv */
void procedural_render_black(uint8_t *buf, int width, int height) {
    size_t total_bytes = (size_t)width * height * 2;
    for (size_t i = 0; i < total_bytes; i += 4) {
        buf[i + 0] = 16;
        buf[i + 1] = 128;
        buf[i + 2] = 16;
        buf[i + 3] = 128;
    }
}

/* standard smpte color bars in yuyv */
void procedural_render_bars(uint8_t *buf, int width, int height) {
    /* 7 standard colors: white, yellow, cyan, green, magenta, red, blue */
    static const uint8_t colors[7][4] = {
        { 235, 128, 235, 128 }, /* white */
        { 210,  16, 210, 146 }, /* yellow */
        { 170, 166, 170,  16 }, /* cyan */
        { 145,  54, 145,  34 }, /* green */
        { 106, 202, 106, 222 }, /* magenta */
        {  81,  90,  81, 240 }, /* red */
        {  41, 240,  41, 110 }  /* blue */
    };

    int bar_width = width / 7;

    for (int y = 0; y < height; y++) {
        uint8_t *row = buf + (size_t)y * width * 2;
        for (int x = 0; x < width; x += 2) {
            int bar_idx = x / bar_width;
            if (bar_idx > 6) bar_idx = 6;

            const uint8_t *c = colors[bar_idx];
            row[x * 2 + 0] = c[0];
            row[x * 2 + 1] = c[1];
            row[x * 2 + 2] = c[2];
            row[x * 2 + 3] = c[3];
        }
    }
}

/* crt television scanlines with phosphor roll */
void procedural_render_crt(uint8_t *buf, int width, int height, uint32_t frame) {
    uint32_t rng = 0x9e3779b9 ^ frame;
    int roll_pos = (int)((frame * 4) % (uint32_t)height);

    for (int y = 0; y < height; y++) {
        uint8_t *row = buf + (size_t)y * width * 2;
        /* scanline raster attenuation */
        bool is_scanline = (y % 3 == 0);
        int line_dist = abs(y - roll_pos);
        if (line_dist > height / 2) line_dist = height - line_dist;
        int roll_boost = (line_dist < 40) ? (40 - line_dist) : 0;

        for (int x = 0; x < width; x += 2) {
            uint32_t r = fast_rand(&rng);
            int grain = (int)(r & 0x1F) - 15;

            int base_y = 60 + roll_boost + grain;
            if (is_scanline) base_y = (base_y * 3) / 5;

            int y_val = base_y < 16 ? 16 : (base_y > 235 ? 235 : base_y);
            row[x * 2 + 0] = (uint8_t)y_val;
            row[x * 2 + 1] = 124; /* subtle green phosphor cast */
            row[x * 2 + 2] = (uint8_t)y_val;
            row[x * 2 + 3] = 124;
        }
    }
}

/* colorful digital glitch with diced pixel blocks */
void procedural_render_glitch(uint8_t *buf, int width, int height, uint32_t frame) {
    uint32_t rng = 0xdeadbeef ^ (frame / 2);
    static const uint8_t palette[6][4] = {
        { 210,  16, 210, 146 }, /* yellow */
        { 170, 166, 170,  16 }, /* cyan */
        { 106, 202, 106, 222 }, /* magenta */
        {  81,  90,  81, 240 }, /* red */
        { 145,  54, 145,  34 }, /* green */
        {  41, 240,  41, 110 }  /* blue */
    };

    int block_w = 64;
    int block_h = 36;
    int num_blocks_x = width / block_w;
    int num_blocks_y = height / block_h;

    for (int by = 0; by < num_blocks_y; by++) {
        for (int bx = 0; bx < num_blocks_x; bx++) {
            uint32_t r = fast_rand(&rng);
            int color_idx = (int)(r % 6);
            bool is_glitch = ((r >> 8) % 4) == 0;
            const uint8_t *c = palette[color_idx];

            for (int y = by * block_h; y < (by + 1) * block_h && y < height; y++) {
                uint8_t *row = buf + (size_t)y * width * 2;
                for (int x = bx * block_w; x < (bx + 1) * block_w && x < width; x += 2) {
                    if (is_glitch) {
                        row[x * 2 + 0] = c[0];
                        row[x * 2 + 1] = c[1];
                        row[x * 2 + 2] = c[2];
                        row[x * 2 + 3] = c[3];
                    } else {
                        /* dark grid block */
                        row[x * 2 + 0] = 24;
                        row[x * 2 + 1] = 128;
                        row[x * 2 + 2] = 24;
                        row[x * 2 + 3] = 128;
                    }
                }
            }
        }
    }
}

/* animated retro geometric shapes and bouncing box */
void procedural_render_shapes(uint8_t *buf, int width, int height, uint32_t frame) {
    /* dark background */
    size_t total_bytes = (size_t)width * height * 2;
    for (size_t i = 0; i < total_bytes; i += 4) {
        buf[i + 0] = 20;
        buf[i + 1] = 128;
        buf[i + 2] = 20;
        buf[i + 3] = 128;
    }

    /* bouncing rectangle */
    int box_w = 240;
    int box_h = 160;
    int max_x = width - box_w;
    int max_y = height - box_h;

    int pos_x = (int)((frame * 6) % (uint32_t)(max_x * 2));
    if (pos_x > max_x) pos_x = max_x * 2 - pos_x;

    int pos_y = (int)((frame * 4) % (uint32_t)(max_y * 2));
    if (pos_y > max_y) pos_y = max_y * 2 - pos_y;

    /* align x to even for yuyv */
    pos_x &= ~1;

    for (int y = pos_y; y < pos_y + box_h && y < height; y++) {
        uint8_t *row = buf + (size_t)y * width * 2;
        for (int x = pos_x; x < pos_x + box_w && x < width; x += 2) {
            /* cyan bouncing box */
            row[x * 2 + 0] = 170;
            row[x * 2 + 1] = 166;
            row[x * 2 + 2] = 170;
            row[x * 2 + 3] = 16;
        }
    }

    /* static retro center crosshair */
    int cx = (width / 2) & ~1;
    int cy = height / 2;
    for (int x = cx - 40; x <= cx + 40; x += 2) {
        if (x >= 0 && x < width) {
            uint8_t *row = buf + (size_t)cy * width * 2;
            row[x * 2 + 0] = 235;
            row[x * 2 + 1] = 128;
            row[x * 2 + 2] = 235;
            row[x * 2 + 3] = 128;
        }
    }
    for (int y = cy - 40; y <= cy + 40; y++) {
        if (y >= 0 && y < height) {
            uint8_t *row = buf + (size_t)y * width * 2;
            row[cx * 2 + 0] = 235;
            row[cx * 2 + 1] = 128;
            row[cx * 2 + 2] = 235;
            row[cx * 2 + 3] = 128;
        }
    }
}
