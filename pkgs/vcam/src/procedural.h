#ifndef VCAM_PROCEDURAL_H
#define VCAM_PROCEDURAL_H

#include "common.h"

void procedural_render_privacy(uint8_t *buf, int width, int height, uint32_t frame);
void procedural_render_black(uint8_t *buf, int width, int height);
void procedural_render_bars(uint8_t *buf, int width, int height);
void procedural_render_crt(uint8_t *buf, int width, int height, uint32_t frame);
void procedural_render_glitch(uint8_t *buf, int width, int height, uint32_t frame);
void procedural_render_shapes(uint8_t *buf, int width, int height, uint32_t frame);

#endif
