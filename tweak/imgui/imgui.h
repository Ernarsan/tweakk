// ImGui - Standalone minimal port for iOS OpenGL ES 2.0
// Based on public domain Dear ImGui concept, adapted for cheat overlay
#pragma once
#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>
#include <math.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

#ifdef __cplusplus
extern "C" {
#endif

// === VECTOR TYPES ===
typedef struct { float x, y; } ImVec2;
typedef struct { float x, y, z, w; } ImVec4;

static inline ImVec2 ImVec2_make(float x, float y) { ImVec2 v = {x, y}; return v; }
static inline ImVec4 ImVec4_make(float x, float y, float z, float w) { ImVec4 v = {x, y, z, w}; return v; }

// === DRAW VERTEX ===
#define IMGUI_VERTEX_SIZE 6
typedef struct {
    float pos[2];
    float uv[2];
    uint8_t col[4];
} ImDrawVert;

// === DRAW CMD ===
typedef struct {
    uint32_t elemCount;
    uint32_t idxOffset;
    uint32_t vtxOffset;
} ImDrawCmd;

// === DRAW LIST ===
typedef struct {
    ImDrawVert *vtxBuf;
    uint32_t vtxCount;
    uint32_t vtxCap;
    uint16_t *idxBuf;
    uint32_t idxCount;
    uint32_t idxCap;
    ImDrawCmd *cmdBuf;
    uint32_t cmdCount;
    uint32_t cmdCap;
} ImDrawList;

// === CONTEXT ===
typedef struct {
    ImDrawList *dl;
    ImVec2 displaySize;
    ImVec2 mousePos;
    bool mouseDown[3];
    float scrollX, scrollY;
    // State
    bool active;
    bool anyActive;
    uint32_t activeId;
    uint32_t hotId;
    // Windows
    float windowX, windowY;
    float windowW, windowH;
    bool windowMoving;
    ImVec2 windowMoveOffset;
    // Style
    float scale;  // content scale (retina-aware)
} ImGuiContext;

// === PUBLIC API ===
void ImGui_Init(ImGuiContext *ctx, int screenW, int screenH, float scale);
void ImGui_NewFrame(ImGuiContext *ctx);
void ImGui_Render(ImGuiContext *ctx);

// Widgets - return true if value changed / clicked
bool ImGui_Checkbox(ImGuiContext *ctx, const char *label, bool *value);
bool ImGui_Button(ImGuiContext *ctx, const char *label, ImVec2 size);
void ImGui_Label(ImGuiContext *ctx, const char *label);
void ImGui_SameLine(ImGuiContext *ctx);
void ImGui_Separator(ImGuiContext *ctx);

// Window helpers
void ImGui_BeginWindow(ImGuiContext *ctx, const char *title, int w, int h);
void ImGui_EndWindow(ImGuiContext *ctx);

// Mouse/Input
void ImGui_SetMousePos(ImGuiContext *ctx, float x, float y);
void ImGui_SetMouseDown(ImGuiContext *ctx, int button, bool down);
void ImGui_SetScroll(ImGuiContext *ctx, float sx, float sy);

// === DRAW PRIMITIVES (internal, exposed for renderer) ===
void ImGuiDL_AddText(ImDrawList *dl, ImVec2 pos, uint32_t col, const char *text);
void ImGuiDL_AddRect(ImDrawList *dl, ImVec2 a, ImVec2 b, uint32_t col, float rounding);
void ImGuiDL_AddRectFilled(ImDrawList *dl, ImVec2 a, ImVec2 b, uint32_t col, float rounding);
void ImGuiDL_AddLine(ImDrawList *dl, ImVec2 a, ImVec2 b, uint32_t col, float thickness);
void ImGuiDL_AddCircleFilled(ImDrawList *dl, ImVec2 c, float r, uint32_t col);

// === COLOR HELPERS ===
static inline uint32_t ImGui_ColorRGBA(uint8_t r, uint8_t g, uint8_t b, uint8_t a) {
    return (r << 0) | (g << 8) | (b << 16) | (a << 24);
}
static inline uint32_t ImGui_ColorFloat(float r, float g, float b, float a) {
    return ImGui_ColorRGBA((uint8_t)(r*255), (uint8_t)(g*255), (uint8_t)(b*255), (uint8_t)(a*255));
}
static inline ImVec4 ImGui_ColorU32(uint32_t col) {
    ImVec4 v = {(float)(col&0xFF)/255.f, (float)((col>>8)&0xFF)/255.f,
                (float)((col>>16)&0xFF)/255.f, (float)((col>>24)&0xFF)/255.f};
    return v;
}

// === FONT (8x8 monochrome bitmap) ===
extern const uint8_t ImGui_Font8x8[256][8];

#ifdef __cplusplus
}
#endif