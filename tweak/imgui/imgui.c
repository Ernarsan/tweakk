// ImGui implementation for iOS OpenGL ES 2.0
#include "imgui.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

// ============================================================
// 8x8 BITMAP FONT (ASCII 32-126)
// ============================================================
const uint8_t ImGui_Font8x8[256][8] = {
    [0 ... 31] = {0,0,0,0,0,0,0,0},
    [32] = {0,0,0,0,0,0,0,0}, // space
    [33] = {0x18,0x18,0x18,0x18,0x18,0x00,0x18,0x00}, // !
    [34] = {0x6C,0x6C,0x28,0x00,0x00,0x00,0x00,0x00}, // "
    [35] = {0x28,0x28,0xFE,0x28,0xFE,0x28,0x28,0x00}, // #
    [36] = {0x10,0x7C,0xD0,0x7C,0x16,0xFC,0x10,0x00}, // $
    [37] = {0x62,0x64,0x08,0x10,0x26,0x46,0x00,0x00}, // %
    [38] = {0x30,0x48,0x30,0x54,0x88,0x84,0x7A,0x00}, // &
    [39] = {0x18,0x18,0x10,0x00,0x00,0x00,0x00,0x00}, // '
    [40] = {0x08,0x10,0x20,0x20,0x20,0x10,0x08,0x00}, // (
    [41] = {0x20,0x10,0x08,0x08,0x08,0x10,0x20,0x00}, // )
    [42] = {0x00,0x24,0x18,0x7E,0x18,0x24,0x00,0x00}, // *
    [43] = {0x00,0x10,0x10,0x7C,0x10,0x10,0x00,0x00}, // +
    [44] = {0x00,0x00,0x00,0x00,0x00,0x18,0x18,0x10}, // ,
    [45] = {0x00,0x00,0x00,0x7C,0x00,0x00,0x00,0x00}, // -
    [46] = {0x00,0x00,0x00,0x00,0x00,0x18,0x18,0x00}, // .
    [47] = {0x02,0x04,0x08,0x10,0x20,0x40,0x80,0x00}, // /
    [48] = {0x38,0x44,0x82,0x82,0x82,0x44,0x38,0x00}, // 0
    [49] = {0x10,0x30,0x50,0x10,0x10,0x10,0x7C,0x00}, // 1
    [50] = {0x38,0x44,0x04,0x08,0x10,0x20,0x7C,0x00}, // 2
    [51] = {0x38,0x44,0x04,0x18,0x04,0x44,0x38,0x00}, // 3
    [52] = {0x08,0x18,0x28,0x48,0xFC,0x08,0x08,0x00}, // 4
    [53] = {0x7C,0x40,0x78,0x04,0x04,0x44,0x38,0x00}, // 5
    [54] = {0x18,0x20,0x40,0x78,0x44,0x44,0x38,0x00}, // 6
    [55] = {0x7C,0x04,0x08,0x10,0x20,0x40,0x40,0x00}, // 7
    [56] = {0x38,0x44,0x44,0x38,0x44,0x44,0x38,0x00}, // 8
    [57] = {0x38,0x44,0x44,0x3C,0x04,0x08,0x30,0x00}, // 9
    [58] = {0x00,0x18,0x18,0x00,0x00,0x18,0x18,0x00}, // :
    [59] = {0x00,0x18,0x18,0x00,0x00,0x18,0x18,0x10}, // ;
    [60] = {0x04,0x08,0x10,0x20,0x10,0x08,0x04,0x00}, // <
    [61] = {0x00,0x00,0x7C,0x00,0x7C,0x00,0x00,0x00}, // =
    [62] = {0x20,0x10,0x08,0x04,0x08,0x10,0x20,0x00}, // >
    [63] = {0x38,0x44,0x04,0x08,0x10,0x00,0x10,0x00}, // ?
    [64] = {0x38,0x44,0x9A,0xAA,0x9A,0x40,0x3C,0x00}, // @
    [65] = {0x10,0x28,0x44,0x44,0x7C,0x44,0x44,0x00}, // A
    [66] = {0x78,0x44,0x44,0x78,0x44,0x44,0x78,0x00}, // B
    [67] = {0x38,0x44,0x40,0x40,0x40,0x44,0x38,0x00}, // C
    [68] = {0x78,0x44,0x44,0x44,0x44,0x44,0x78,0x00}, // D
    [69] = {0x7C,0x40,0x40,0x78,0x40,0x40,0x7C,0x00}, // E
    [70] = {0x7C,0x40,0x40,0x78,0x40,0x40,0x40,0x00}, // F
    [71] = {0x3C,0x40,0x40,0x5C,0x44,0x44,0x3C,0x00}, // G
    [72] = {0x44,0x44,0x44,0x7C,0x44,0x44,0x44,0x00}, // H
    [73] = {0x38,0x10,0x10,0x10,0x10,0x10,0x38,0x00}, // I
    [74] = {0x04,0x04,0x04,0x04,0x04,0x44,0x38,0x00}, // J
    [75] = {0x44,0x48,0x50,0x60,0x50,0x48,0x44,0x00}, // K
    [76] = {0x40,0x40,0x40,0x40,0x40,0x40,0x7C,0x00}, // L
    [77] = {0x44,0x6C,0x54,0x54,0x44,0x44,0x44,0x00}, // M
    [78] = {0x44,0x64,0x54,0x4C,0x44,0x44,0x44,0x00}, // N
    [79] = {0x38,0x44,0x44,0x44,0x44,0x44,0x38,0x00}, // O
    [80] = {0x78,0x44,0x44,0x78,0x40,0x40,0x40,0x00}, // P
    [81] = {0x38,0x44,0x44,0x44,0x54,0x48,0x34,0x00}, // Q
    [82] = {0x78,0x44,0x44,0x78,0x48,0x44,0x44,0x00}, // R
    [83] = {0x3C,0x40,0x40,0x38,0x04,0x04,0x78,0x00}, // S
    [84] = {0x7C,0x10,0x10,0x10,0x10,0x10,0x10,0x00}, // T
    [85] = {0x44,0x44,0x44,0x44,0x44,0x44,0x38,0x00}, // U
    [86] = {0x44,0x44,0x44,0x44,0x28,0x28,0x10,0x00}, // V
    [87] = {0x44,0x44,0x44,0x54,0x54,0x6C,0x44,0x00}, // W
    [88] = {0x44,0x44,0x28,0x10,0x28,0x44,0x44,0x00}, // X
    [89] = {0x44,0x44,0x28,0x10,0x10,0x10,0x10,0x00}, // Y
    [90] = {0x7C,0x04,0x08,0x10,0x20,0x40,0x7C,0x00}, // Z
    [91] = {0x38,0x20,0x20,0x20,0x20,0x20,0x38,0x00}, // [
    [92] = {0x80,0x40,0x20,0x10,0x08,0x04,0x02,0x00}, // backslash
    [93] = {0x38,0x08,0x08,0x08,0x08,0x08,0x38,0x00}, // ]
    [94] = {0x10,0x28,0x44,0x00,0x00,0x00,0x00,0x00}, // ^
    [95] = {0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xFE}, // _
    [96] = {0x20,0x10,0x08,0x00,0x00,0x00,0x00,0x00}, // `
    [97] = {0x00,0x00,0x3C,0x04,0x3C,0x44,0x3C,0x00}, // a
    [98] = {0x40,0x40,0x58,0x64,0x44,0x64,0x58,0x00}, // b
    [99] = {0x00,0x00,0x3C,0x40,0x40,0x40,0x3C,0x00}, // c
    [100]= {0x04,0x04,0x3C,0x44,0x44,0x4C,0x34,0x00}, // d
    [101]= {0x00,0x00,0x38,0x44,0x7C,0x40,0x3C,0x00}, // e
    [102]= {0x18,0x24,0x20,0x70,0x20,0x20,0x20,0x00}, // f
    [103]= {0x00,0x00,0x34,0x4C,0x44,0x3C,0x04,0x38}, // g
    [104]= {0x40,0x40,0x58,0x64,0x44,0x44,0x44,0x00}, // h
    [105]= {0x10,0x00,0x30,0x10,0x10,0x10,0x38,0x00}, // i
    [106]= {0x04,0x00,0x0C,0x04,0x04,0x04,0x44,0x38}, // j
    [107]= {0x40,0x40,0x44,0x48,0x70,0x48,0x44,0x00}, // k
    [108]= {0x30,0x10,0x10,0x10,0x10,0x10,0x38,0x00}, // l
    [109]= {0x00,0x00,0x68,0x54,0x54,0x44,0x44,0x00}, // m
    [110]= {0x00,0x00,0x58,0x64,0x44,0x44,0x44,0x00}, // n
    [111]= {0x00,0x00,0x38,0x44,0x44,0x44,0x38,0x00}, // o
    [112]= {0x00,0x00,0x58,0x64,0x44,0x64,0x58,0x40}, // p
    [113]= {0x00,0x00,0x34,0x4C,0x44,0x4C,0x34,0x04}, // q
    [114]= {0x00,0x00,0x5C,0x60,0x40,0x40,0x40,0x00}, // r
    [115]= {0x00,0x00,0x3C,0x40,0x38,0x04,0x78,0x00}, // s
    [116]= {0x20,0x20,0x70,0x20,0x20,0x24,0x18,0x00}, // t
    [117]= {0x00,0x00,0x44,0x44,0x44,0x4C,0x34,0x00}, // u
    [118]= {0x00,0x00,0x44,0x44,0x44,0x28,0x10,0x00}, // v
    [119]= {0x00,0x00,0x44,0x44,0x54,0x54,0x28,0x00}, // w
    [120]= {0x00,0x00,0x44,0x28,0x10,0x28,0x44,0x00}, // x
    [121]= {0x00,0x00,0x44,0x44,0x28,0x10,0x20,0x40}, // y
    [122]= {0x00,0x00,0x78,0x08,0x10,0x20,0x78,0x00}, // z
    [123]= {0x08,0x10,0x10,0x20,0x10,0x10,0x08,0x00}, // {
    [124]= {0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x00}, // |
    [125]= {0x20,0x10,0x10,0x08,0x10,0x10,0x20,0x00}, // }
    [126]= {0x28,0x50,0x00,0x00,0x00,0x00,0x00,0x00}, // ~
};

// ============================================================
// DRAW LIST ALLOC
// ============================================================
static ImDrawList* DL_Alloc(void) {
    ImDrawList *dl = (ImDrawList*)calloc(1, sizeof(ImDrawList));
    dl->vtxCap = 4096;
    dl->idxCap = 8192;
    dl->cmdCap = 128;
    dl->vtxBuf = (ImDrawVert*)malloc(dl->vtxCap * sizeof(ImDrawVert));
    dl->idxBuf = (uint16_t*)malloc(dl->idxCap * sizeof(uint16_t));
    dl->cmdBuf = (ImDrawCmd*)malloc(dl->cmdCap * sizeof(ImDrawCmd));
    return dl;
}

static void DL_Clear(ImDrawList *dl) {
    dl->vtxCount = 0;
    dl->idxCount = 0;
    dl->cmdCount = 0;
}

static void DL_ReserveVtx(ImDrawList *dl, uint32_t n) {
    if (dl->vtxCount + n > dl->vtxCap) {
        dl->vtxCap *= 2;
        dl->vtxBuf = (ImDrawVert*)realloc(dl->vtxBuf, dl->vtxCap * sizeof(ImDrawVert));
    }
}

static void DL_ReserveIdx(ImDrawList *dl, uint32_t n) {
    if (dl->idxCount + n > dl->idxCap) {
        dl->idxCap *= 2;
        dl->idxBuf = (uint16_t*)realloc(dl->idxBuf, dl->idxCap * sizeof(uint16_t));
    }
}

static void DL_ReserveCmd(ImDrawList *dl) {
    if (dl->cmdCount >= dl->cmdCap) {
        dl->cmdCap *= 2;
        dl->cmdBuf = (ImDrawCmd*)realloc(dl->cmdBuf, dl->cmdCap * sizeof(ImDrawCmd));
    }
}

static uint32_t DL_Vtx(ImDrawList *dl, float x, float y, uint32_t col) {
    uint32_t idx = dl->vtxCount;
    DL_ReserveVtx(dl, 1);
    ImDrawVert *v = &dl->vtxBuf[dl->vtxCount++];
    v->pos[0] = x; v->pos[1] = y;
    v->uv[0] = 0; v->uv[1] = 0;
    v->col[0] = col & 0xFF;
    v->col[1] = (col >> 8) & 0xFF;
    v->col[2] = (col >> 16) & 0xFF;
    v->col[3] = (col >> 24) & 0xFF;
    return idx;
}

static void DL_FlushCmd(ImDrawList *dl) {
    DL_ReserveCmd(dl);
    uint32_t offset = 0;
    if (dl->cmdCount > 0)
        offset = dl->cmdBuf[dl->cmdCount-1].idxOffset + dl->cmdBuf[dl->cmdCount-1].elemCount;
    dl->cmdBuf[dl->cmdCount].vtxOffset = 0; // all verts in one buffer
    dl->cmdBuf[dl->cmdCount].idxOffset = offset;
    dl->cmdBuf[dl->cmdCount].elemCount = 0;
    dl->cmdCount++;
}

static void DL_PrimVtx(ImDrawList *dl, float x, float y, uint32_t col) {
    uint32_t vi = DL_Vtx(dl, x, y, col);
    uint32_t ci = dl->cmdCount - 1;
    DL_ReserveIdx(dl, 1);
    dl->idxBuf[dl->idxCount++] = (uint16_t)vi;
    dl->cmdBuf[ci].elemCount++;
}

// ============================================================
// DRAW PRIMITIVE IMPLEMENTATIONS
// ============================================================
void ImGuiDL_AddText(ImDrawList *dl, ImVec2 pos, uint32_t col, const char *text) {
    if (!text || !*text) return;
    DL_FlushCmd(dl);
    uint32_t cmdIdx = dl->cmdCount - 1;
    float x = pos.x, y = pos.y;
    while (*text) {
        unsigned char ch = (unsigned char)*text;
        if (ch == '\n') { y += 9; x = pos.x; text++; continue; }
        if (ch < 32 || ch > 126) { ch = ' '; }
        const uint8_t *glyph = ImGui_Font8x8[ch];
        for (int row = 0; row < 8; row++) {
            uint8_t bits = glyph[row];
            for (int colBit = 0; colBit < 8; colBit++) {
                if (bits & (0x80 >> colBit)) {
                    float px = x + colBit;
                    float py = y + row;
                    uint32_t vi = DL_Vtx(dl, px, py, col);
                    DL_ReserveIdx(dl, 1);
                    dl->idxBuf[dl->idxCount++] = (uint16_t)vi;
                    dl->cmdBuf[cmdIdx].elemCount++;
                }
            }
        }
        x += 8;
        text++;
    }
}

void ImGuiDL_AddRect(ImDrawList *dl, ImVec2 a, ImVec2 b, uint32_t col, float rounding) {
    (void)rounding; // no rounding in basic impl
    DL_FlushCmd(dl);
    uint32_t cmdIdx = dl->cmdCount - 1;
    // Top
    for (float x = a.x; x <= b.x; x += 1) {
        uint32_t viT = DL_Vtx(dl, x, a.y, col);
        uint32_t viB = DL_Vtx(dl, x, b.y, col);
        DL_ReserveIdx(dl, 2);
        dl->idxBuf[dl->idxCount++] = (uint16_t)viT;
        dl->idxBuf[dl->idxCount++] = (uint16_t)viB;
        dl->cmdBuf[cmdIdx].elemCount += 2;
    }
    // Sides (avoid corners)
    for (float y = a.y + 1; y < b.y; y += 1) {
        uint32_t viL = DL_Vtx(dl, a.x, y, col);
        uint32_t viR = DL_Vtx(dl, b.x, y, col);
        DL_ReserveIdx(dl, 2);
        dl->idxBuf[dl->idxCount++] = (uint16_t)viL;
        dl->idxBuf[dl->idxCount++] = (uint16_t)viR;
        dl->cmdBuf[cmdIdx].elemCount += 2;
    }
}

void ImGuiDL_AddRectFilled(ImDrawList *dl, ImVec2 a, ImVec2 b, uint32_t col, float rounding) {
    (void)rounding;
    DL_FlushCmd(dl);
    uint32_t cmdIdx = dl->cmdCount - 1;
    for (float y = a.y; y <= b.y; y += 1) {
        for (float x = a.x; x <= b.x; x += 1) {
            uint32_t vi = DL_Vtx(dl, x, y, col);
            DL_ReserveIdx(dl, 1);
            dl->idxBuf[dl->idxCount++] = (uint16_t)vi;
            dl->cmdBuf[cmdIdx].elemCount++;
        }
    }
}

void ImGuiDL_AddLine(ImDrawList *dl, ImVec2 a, ImVec2 b, uint32_t col, float thickness) {
    DL_FlushCmd(dl);
    uint32_t cmdIdx = dl->cmdCount - 1;
    float dx = b.x - a.x, dy = b.y - a.y;
    float len = sqrtf(dx*dx + dy*dy);
    if (len < 0.5f) return;
    float steps = len;
    for (float t = 0; t <= 1.0f; t += (1.0f / steps)) {
        float px = a.x + dx * t;
        float py = a.y + dy * t;
        uint32_t vi = DL_Vtx(dl, px, py, col);
        DL_ReserveIdx(dl, 1);
        dl->idxBuf[dl->idxCount++] = (uint16_t)vi;
        dl->cmdBuf[cmdIdx].elemCount++;
    }
}

void ImGuiDL_AddCircleFilled(ImDrawList *dl, ImVec2 c, float r, uint32_t col) {
    DL_FlushCmd(dl);
    uint32_t cmdIdx = dl->cmdCount - 1;
    for (float y = -r; y <= r; y += 1) {
        for (float x = -r; x <= r; x += 1) {
            if (x*x + y*y <= r*r) {
                uint32_t vi = DL_Vtx(dl, c.x + x, c.y + y, col);
                DL_ReserveIdx(dl, 1);
                dl->idxBuf[dl->idxCount++] = (uint16_t)vi;
                dl->cmdBuf[cmdIdx].elemCount++;
            }
        }
    }
}

// ============================================================
// TEXT MEASUREMENT
// ============================================================
static ImVec2 ImGui_CalcTextSize(const char *text) {
    ImVec2 sz = {0, 8};
    float lineW = 0;
    while (text && *text) {
        if (*text == '\n') { sz.y += 9; if (lineW > sz.x) sz.x = lineW; lineW = 0; }
        else lineW += 8;
        text++;
    }
    if (lineW > sz.x) sz.x = lineW;
    return sz;
}

// ============================================================
// CONTEXT API
// ============================================================
void ImGui_Init(ImGuiContext *ctx, int screenW, int screenH, float scale) {
    memset(ctx, 0, sizeof(ImGuiContext));
    ctx->displaySize.x = (float)screenW;
    ctx->displaySize.y = (float)screenH;
    ctx->scale = scale;
    ctx->dl = DL_Alloc();
}

void ImGui_NewFrame(ImGuiContext *ctx) {
    DL_Clear(ctx->dl);
    ctx->active = false;
    ctx->anyActive = false;
    ctx->windowMoving = false;
}

void ImGui_Render(ImGuiContext *ctx) {
    ImDrawList *dl = ctx->dl;
    if (dl->cmdCount == 0) DL_FlushCmd(dl);
    
    // Set up GL ortho projection
    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();
    glOrthof(0, ctx->displaySize.x, ctx->displaySize.y, 0, -1, 1);
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glLoadIdentity();
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDisable(GL_TEXTURE_2D);
    glDisable(GL_DEPTH_TEST);
    glVertexPointer(2, GL_FLOAT, sizeof(ImDrawVert), &dl->vtxBuf[0].pos);
    glColorPointer(4, GL_UNSIGNED_BYTE, sizeof(ImDrawVert), &dl->vtxBuf[0].col);
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
    glPointSize(1.0f);
    
    for (uint32_t i = 0; i < dl->cmdCount; i++) {
        ImDrawCmd *cmd = &dl->cmdBuf[i];
        if (cmd->elemCount == 0) continue;
        glDrawElements(GL_POINTS, cmd->elemCount, GL_UNSIGNED_SHORT,
                       &dl->idxBuf[cmd->idxOffset]);
    }
    
    glDisableClientState(GL_COLOR_ARRAY);
    glDisableClientState(GL_VERTEX_ARRAY);
    glEnable(GL_TEXTURE_2D);
    glDisable(GL_BLEND);
    
    glMatrixMode(GL_PROJECTION);
    glPopMatrix();
    glMatrixMode(GL_MODELVIEW);
    glPopMatrix();
}

// ============================================================
// WIDGETS
// ============================================================
#define IMGUI_CHECKBOX_SIZE 14
#define IMGUI_ITEM_SPACING 4
#define IMGUI_LINE_HEIGHT 22
#define IMGUI_PADDING 10

void ImGui_BeginWindow(ImGuiContext *ctx, const char *title, int w, int h) {
    ctx->windowW = (float)w;
    ctx->windowH = (float)h;
    ctx->windowX = (ctx->displaySize.x - ctx->windowW) / 2.0f;
    ctx->windowY = (ctx->displaySize.y - ctx->windowH) / 2.0f;
    
    // Title bar
    float titleH = 28.0f;
    uint32_t titleCol = ImGui_ColorRGBA(30, 35, 45, 240);
    uint32_t borderCol = ImGui_ColorRGBA(90, 130, 220, 200);
    uint32_t bgCol = ImGui_ColorRGBA(20, 22, 28, 235);
    
    ImGuiDL_AddRectFilled(ctx->dl, ImVec2_make(ctx->windowX, ctx->windowY),
                          ImVec2_make(ctx->windowX + ctx->windowW, ctx->windowY + ctx->windowH),
                          bgCol, 0);
    ImGuiDL_AddRect(ctx->dl, ImVec2_make(ctx->windowX, ctx->windowY),
                    ImVec2_make(ctx->windowX + ctx->windowW, ctx->windowY + ctx->windowH),
                    borderCol, 0);
    ImGuiDL_AddRectFilled(ctx->dl, ImVec2_make(ctx->windowX, ctx->windowY),
                          ImVec2_make(ctx->windowX + ctx->windowW, ctx->windowY + titleH),
                          titleCol, 0);
    ImGuiDL_AddLine(ctx->dl, ImVec2_make(ctx->windowX, ctx->windowY + titleH),
                    ImVec2_make(ctx->windowX + ctx->windowW, ctx->windowY + titleH),
                    borderCol, 1);
    // Title text
    ImGuiDL_AddText(ctx->dl, ImVec2_make(ctx->windowX + 8, ctx->windowY + 6),
                    ImGui_ColorRGBA(200, 210, 230, 255), title);
    
    ctx->windowY += titleH + IMGUI_PADDING;
    ctx->windowX += IMGUI_PADDING;
    ctx->windowW -= IMGUI_PADDING * 2;
    ctx->windowH = ctx->windowY + (ctx->windowH - titleH - IMGUI_PADDING);
}

void ImGui_EndWindow(ImGuiContext *ctx) {
    // nothing to clean
}

bool ImGui_Checkbox(ImGuiContext *ctx, const char *label, bool *value) {
    float x = ctx->windowX;
    float y = ctx->windowY;
    float boxSize = IMGUI_CHECKBOX_SIZE;
    float totalH = IMGUI_LINE_HEIGHT;
    
    uint32_t boxCol = *value ? ImGui_ColorRGBA(60, 180, 75, 255) : ImGui_ColorRGBA(40, 42, 50, 200);
    uint32_t boxBorder = ImGui_ColorRGBA(120, 130, 150, 200);
    uint32_t textCol = ImGui_ColorRGBA(210, 215, 225, 255);
    
    ImGuiDL_AddRectFilled(ctx->dl, ImVec2_make(x, y), ImVec2_make(x + boxSize, y + boxSize),
                          ImGui_ColorRGBA(30, 32, 38, 200), 0);
    ImGuiDL_AddRect(ctx->dl, ImVec2_make(x, y), ImVec2_make(x + boxSize, y + boxSize),
                    boxBorder, 0);
    if (*value) {
        // Checkmark
        ImGuiDL_AddLine(ctx->dl, ImVec2_make(x + 2, y + 7), ImVec2_make(x + 5, y + 11),
                        boxCol, 2);
        ImGuiDL_AddLine(ctx->dl, ImVec2_make(x + 5, y + 11), ImVec2_make(x + 12, y + 3),
                        boxCol, 2);
    }
    
    ImGuiDL_AddText(ctx->dl, ImVec2_make(x + boxSize + 8, y + 3), textCol, label);
    
    ctx->windowY += totalH;
    
    // Hit testing
    if (ctx->mouseDown[0]) {
        float mx = ctx->mousePos.x, my = ctx->mousePos.y;
        if (mx >= x && mx <= x + ctx->windowW && my >= y && my <= y + totalH) {
            *value = !*value;
            return true;
        }
    }
    return false;
}

bool ImGui_Button(ImGuiContext *ctx, const char *label, ImVec2 size) {
    if (size.x <= 0) size.x = 80;
    if (size.y <= 0) size.y = 24;
    
    float x = ctx->windowX;
    float y = ctx->windowY;
    
    uint32_t bg = ImGui_ColorRGBA(45, 50, 65, 230);
    uint32_t border = ImGui_ColorRGBA(90, 110, 160, 200);
    
    // Hover
    float mx = ctx->mousePos.x, my = ctx->mousePos.y;
    bool hover = (mx >= x && mx <= x + size.x && my >= y && my <= y + size.y);
    if (hover) {
        bg = ImGui_ColorRGBA(55, 65, 90, 240);
    }
    
    ImGuiDL_AddRectFilled(ctx->dl, ImVec2_make(x, y), ImVec2_make(x + size.x, y + size.y), bg, 0);
    ImGuiDL_AddRect(ctx->dl, ImVec2_make(x, y), ImVec2_make(x + size.x, y + size.y), border, 0);
    
    // Center text
    ImVec2 tsz = ImGui_CalcTextSize(label);
    float tx = x + (size.x - tsz.x) / 2;
    float ty = y + (size.y - tsz.y) / 2;
    ImGuiDL_AddText(ctx->dl, ImVec2_make(tx, ty), ImGui_ColorRGBA(210, 215, 225, 255), label);
    
    ctx->windowY += size.y + IMGUI_ITEM_SPACING;
    
    if (hover && ctx->mouseDown[0]) return true;
    return false;
}

void ImGui_Label(ImGuiContext *ctx, const char *label) {
    ImGuiDL_AddText(ctx->dl,
                    ImVec2_make(ctx->windowX, ctx->windowY),
                    ImGui_ColorRGBA(170, 180, 200, 255), label);
    ctx->windowY += IMGUI_LINE_HEIGHT;
}

void ImGui_SameLine(ImGuiContext *ctx) {
    // Not fully implemented in this minimal port
}

void ImGui_Separator(ImGuiContext *ctx) {
    float y = ctx->windowY;
    ImGuiDL_AddLine(ctx->dl,
                    ImVec2_make(ctx->windowX, y),
                    ImVec2_make(ctx->windowX + ctx->windowW, y),
                    ImGui_ColorRGBA(60, 65, 80, 150), 1);
    ctx->windowY += 8;
}

void ImGui_SetMousePos(ImGuiContext *ctx, float x, float y) {
    ctx->mousePos.x = x;
    ctx->mousePos.y = y;
}

void ImGui_SetMouseDown(ImGuiContext *ctx, int button, bool down) {
    if (button >= 0 && button < 3) ctx->mouseDown[button] = down;
}

void ImGui_SetScroll(ImGuiContext *ctx, float sx, float sy) {
    ctx->scrollX = sx;
    ctx->scrollY = sy;
}