// ============================================================
// Standoff2 Cheat v2.0 — без ImGui (только ESP, Wallhack, NoRecoil)
// Управление: Volume Down — включить/выключить все функции
// ============================================================
#import <OpenGLES/ES1/gl.h>
#import <UIKit/UIKit.h>
#import <mach/mach.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <substrate.h>

// ============================================================
// OFFSETS — Standoff2 0.39.1 f1
// ============================================================
#define OFF_DWLOCALPLAYER   0x18AC0C8
#define OFF_DWENTITYLIST    0x18AD0D8
#define OFF_DWVIEWMATRIX    0x11A210

#define OFF_M_IHEALTH       0x5C
#define OFF_M_ITEAMNUM      0xA0
#define OFF_M_VECORIGIN     0x44
#define OFF_M_VECVIEWOFFSET 0x108
#define OFF_M_AIMPUNCHANGLE 0x303C
#define OFF_M_VIEWPUNCH     0x12704
#define OFF_M_BONE          0x10C
#define OFF_M_BSPOTTED      0x104

#define ENTITY_SIZE         0x10
#define MAX_PLAYERS         32

// ============================================================
// STATE
// ============================================================
static BOOL g_cheatEnabled    = YES;
static mach_port_t g_taskPort = MACH_PORT_NULL;
static uintptr_t g_baseAddress = 0;
static int g_screenW = 0;
static int g_screenH = 0;

// ============================================================
// MEMORY HELPERS
// ============================================================
static uintptr_t findBaseAddress(void) {
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "/Standoff2") && !strstr(name, ".dylib")) {
            return (uintptr_t)_dyld_get_image_vmaddr_slide(i);
        }
    }
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "Standoff2")) {
            return (uintptr_t)_dyld_get_image_vmaddr_slide(i);
        }
    }
    return 0;
}

static bool memRead(uintptr_t addr, void *buffer, size_t size) {
    if (g_taskPort == MACH_PORT_NULL || addr == 0) return false;
    vm_size_t outSize = 0;
    kern_return_t kr = vm_read_overwrite(g_taskPort, (vm_address_t)addr, size,
                                          (vm_address_t)buffer, &outSize);
    return (kr == KERN_SUCCESS && outSize == size);
}

static uintptr_t memReadPtr(uintptr_t addr) {
    uintptr_t val = 0;
    memRead(addr, &val, sizeof(val));
    return val;
}

static int memReadInt(uintptr_t addr) {
    int val = 0;
    memRead(addr, &val, sizeof(val));
    return val;
}

static void memWrite(uintptr_t addr, const void *buffer, size_t size) {
    if (g_taskPort == MACH_PORT_NULL || addr == 0) return;
    vm_write(g_taskPort, (vm_address_t)addr, (vm_address_t)buffer, (mach_msg_type_number_t)size);
}

// ============================================================
// MATH
// ============================================================
typedef struct { float x, y, z; } vec3_t;
typedef struct { float x, y; } vec2_t;
typedef struct { float m[4][4]; } matrix4x4_t;

static bool worldToScreen(vec3_t worldPos, vec2_t *screenOut, matrix4x4_t viewMatrix,
                          int screenW, int screenH) {
    vec3_t transform;
    transform.x = viewMatrix.m[0][0] * worldPos.x + viewMatrix.m[0][1] * worldPos.y +
                  viewMatrix.m[0][2] * worldPos.z + viewMatrix.m[0][3];
    transform.y = viewMatrix.m[1][0] * worldPos.x + viewMatrix.m[1][1] * worldPos.y +
                  viewMatrix.m[1][2] * worldPos.z + viewMatrix.m[1][3];
    transform.z = viewMatrix.m[3][0] * worldPos.x + viewMatrix.m[3][1] * worldPos.y +
                  viewMatrix.m[3][2] * worldPos.z + viewMatrix.m[3][3];

    if (transform.z < 0.001f) return false;

    float invW = 1.0f / transform.z;
    float x = (screenW * 0.5f) * (1.0f + viewMatrix.m[0][0] * worldPos.x * invW +
                                   viewMatrix.m[0][1] * worldPos.y * invW +
                                   viewMatrix.m[0][2] * worldPos.z * invW +
                                   viewMatrix.m[0][3] * invW);
    float y = (screenH * 0.5f) * (1.0f - viewMatrix.m[1][0] * worldPos.x * invW -
                                   viewMatrix.m[1][1] * worldPos.y * invW -
                                   viewMatrix.m[1][2] * worldPos.z * invW -
                                   viewMatrix.m[1][3] * invW);

    screenOut->x = x;
    screenOut->y = y;
    return (x >= 0 && x <= screenW && y >= 0 && y <= screenH);
}

// ============================================================
// DRAW FUNCTIONS
// ============================================================
static void drawESPBox(float x, float y, float w, float h, uint32_t color) {
    GLfloat verts[] = { x, y, x+w, y, x+w, y+h, x, y+h };
    glVertexPointer(2, GL_FLOAT, 0, verts);
    glEnableClientState(GL_VERTEX_ARRAY);
    glColor4f(((color>>0) & 0xFF) / 255.f,
              ((color>>8) & 0xFF) / 255.f,
              ((color>>16) & 0xFF) / 255.f,
              ((color>>24) & 0xFF) / 255.f);
    glDrawArrays(GL_LINE_LOOP, 0, 4);
    glDisableClientState(GL_VERTEX_ARRAY);
}

static void drawESPFilledRect(float x, float y, float w, float h, uint32_t color) {
    GLfloat verts[] = { x, y, x+w, y, x+w, y+h, x, y+h };
    GLubyte idx[] = { 0, 1, 2, 0, 2, 3 };
    glVertexPointer(2, GL_FLOAT, 0, verts);
    glEnableClientState(GL_VERTEX_ARRAY);
    glColor4f(((color>>0) & 0xFF) / 255.f,
              ((color>>8) & 0xFF) / 255.f,
              ((color>>16) & 0xFF) / 255.f,
              ((color>>24) & 0xFF) / 255.f);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, idx);
    glDisableClientState(GL_VERTEX_ARRAY);
}

static void drawESPLine(float x1, float y1, float x2, float y2, uint32_t color) {
    GLfloat verts[] = { x1, y1, x2, y2 };
    glVertexPointer(2, GL_FLOAT, 0, verts);
    glEnableClientState(GL_VERTEX_ARRAY);
    glColor4f(((color>>0) & 0xFF) / 255.f,
              ((color>>8) & 0xFF) / 255.f,
              ((color>>16) & 0xFF) / 255.f,
              ((color>>24) & 0xFF) / 255.f);
    glDrawArrays(GL_LINES, 0, 2);
    glDisableClientState(GL_VERTEX_ARRAY);
}

// ============================================================
// HACKS
// ============================================================
static void runWallhack(void) {
    if (!g_cheatEnabled || !g_baseAddress) return;
    uintptr_t entityListBase = memReadPtr(g_baseAddress + OFF_DWENTITYLIST);
    if (!entityListBase) return;
    uintptr_t localPlayer = memReadPtr(g_baseAddress + OFF_DWLOCALPLAYER);
    if (!localPlayer) return;
    int localTeam = memReadInt(localPlayer + OFF_M_ITEAMNUM);
    for (int i = 0; i < MAX_PLAYERS; i++) {
        uintptr_t entityPtr = memReadPtr(entityListBase + i * ENTITY_SIZE);
        if (!entityPtr || entityPtr == localPlayer) continue;
        int health = memReadInt(entityPtr + OFF_M_IHEALTH);
        if (health <= 0 || health > 150) continue;
        int team = memReadInt(entityPtr + OFF_M_ITEAMNUM);
        if (team == localTeam) continue;
        int spotted = 1;
        memWrite(entityPtr + OFF_M_BSPOTTED, &spotted, sizeof(spotted));
    }
}

static void runNoRecoil(void) {
    if (!g_cheatEnabled || !g_baseAddress) return;
    uintptr_t localPlayer = memReadPtr(g_baseAddress + OFF_DWLOCALPLAYER);
    if (!localPlayer) return;
    float zero[3] = { 0.0f, 0.0f, 0.0f };
    memWrite(localPlayer + OFF_M_AIMPUNCHANGLE, zero, sizeof(zero));
    memWrite(localPlayer + OFF_M_VIEWPUNCH, zero, sizeof(zero));
}

static void runESP(void) {
    if (!g_cheatEnabled || !g_baseAddress) return;
    uintptr_t entityListBase = memReadPtr(g_baseAddress + OFF_DWENTITYLIST);
    if (!entityListBase) return;
    uintptr_t localPlayer = memReadPtr(g_baseAddress + OFF_DWLOCALPLAYER);
    if (!localPlayer) return;
    matrix4x4_t viewMatrix;
    if (!memRead(g_baseAddress + OFF_DWVIEWMATRIX, &viewMatrix, sizeof(viewMatrix))) return;
    int localTeam = memReadInt(localPlayer + OFF_M_ITEAMNUM);

    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();
    glOrthof(0, g_screenW, g_screenH, 0, -1, 1);
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glLoadIdentity();
    glDisable(GL_TEXTURE_2D);
    glDisable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glLineWidth(2.0f);

    for (int i = 0; i < MAX_PLAYERS; i++) {
        uintptr_t entityPtr = memReadPtr(entityListBase + i * ENTITY_SIZE);
        if (!entityPtr || entityPtr == localPlayer) continue;
        int health = memReadInt(entityPtr + OFF_M_IHEALTH);
        if (health <= 0 || health > 150) continue;
        int team = memReadInt(entityPtr + OFF_M_ITEAMNUM);
        if (team == localTeam) continue;

        vec3_t origin;
        memRead(entityPtr + OFF_M_VECORIGIN, &origin, sizeof(origin));
        vec3_t viewOffset;
        memRead(entityPtr + OFF_M_VECVIEWOFFSET, &viewOffset, sizeof(viewOffset));
        vec3_t headPos = { origin.x + viewOffset.x,
                           origin.y + viewOffset.y,
                           origin.z + viewOffset.z };

        vec2_t footScreen, headScreen;
        if (!worldToScreen(origin, &footScreen, viewMatrix, g_screenW, g_screenH) ||
            !worldToScreen(headPos, &headScreen, viewMatrix, g_screenW, g_screenH)) {
            continue;
        }

        float height = fabsf(footScreen.y - headScreen.y);
        if (height < 10.0f) continue;
        float width = height * 0.45f;
        float boxX = headScreen.x - width * 0.5f;
        float boxY = headScreen.y;

        uint32_t colorEnemy = 0xFF0000FF;
        drawESPBox(boxX, boxY, width, height, colorEnemy);
        drawESPLine(headScreen.x, footScreen.y, headScreen.x, g_screenH, 0x40FF00FF);

        float healthPct = (float)health / 100.0f;
        if (healthPct > 1.0f) healthPct = 1.0f;
        if (healthPct < 0.0f) healthPct = 0.0f;
        float barW = 4.0f;
        float barX = boxX - barW - 2.0f;
        float healthH = height * healthPct;
        float barY = boxY + (height - healthH);
        drawESPFilledRect(barX, boxY, barW, height, 0x00000080);
        drawESPFilledRect(barX, barY, barW, healthH, 0x00FF00FF);
    }

    glPopMatrix();
    glMatrixMode(GL_PROJECTION);
    glPopMatrix();
    glMatrixMode(GL_MODELVIEW);
}

// ============================================================
// HOOKS
// ============================================================
static void (*orig_UIApplication_sendEvent)(id, SEL, UIEvent *);
static void hook_UIApplication_sendEvent(id self, SEL _cmd, UIEvent *event) {
    orig_UIApplication_sendEvent(self, _cmd, event);
    if (event.type == UIEventTypePresses) {
        NSSet *presses = [event valueForKey:@"presses"];
        if (!presses) return;
        for (UIPress *press in presses) {
            if (press.phase != UIPressPhaseBegan) continue;
            BOOL isVolDown = NO;
            if ([press respondsToSelector:@selector(key)]) {
                NSString *key = [press valueForKey:@"key"];
                if ([key isEqualToString:UIKeyInputLeftArrow]) isVolDown = YES;
            } else {
                if (press.type == UIPressTypeDownArrow) isVolDown = YES;
            }
            if (isVolDown) {
                g_cheatEnabled = !g_cheatEnabled;
                NSLog(@"[Cheat] Cheat toggled: %d", g_cheatEnabled);
            }
        }
    }
}

static void (*orig_EAGLContext_presentRenderbuffer)(id, SEL, GLint);
static void hook_EAGLContext_presentRenderbuffer(id self, SEL _cmd, GLint renderbuffer) {
    static BOOL initialized = NO;
    if (!initialized) {
        g_taskPort = mach_task_self();
        g_baseAddress = findBaseAddress();
        NSLog(@"[Cheat] Base: 0x%lx", (unsigned long)g_baseAddress);
        UIScreen *screen = [UIScreen mainScreen];
        CGSize nativeSize = screen.nativeBounds.size;
        g_screenW = (int)nativeSize.width;
        g_screenH = (int)nativeSize.height;
        initialized = YES;
    }
    orig_EAGLContext_presentRenderbuffer(self, _cmd, renderbuffer);
    if (!g_baseAddress) return;
    runESP();
    runWallhack();
    runNoRecoil();
}

// ============================================================
// CONSTRUCTOR
// ============================================================
%ctor {
    @autoreleasepool {
        NSLog(@"[Cheat] Standoff2 Cheat v2.0 (lite) loading...");
        g_taskPort = mach_task_self();
        g_baseAddress = findBaseAddress();
        if (!g_baseAddress) {
            NSLog(@"[Cheat] ERROR: Cannot find Standoff2 base address!");
            return;
        }
        g_screenW = (int)[UIScreen mainScreen].nativeBounds.size.width;
        g_screenH = (int)[UIScreen mainScreen].nativeBounds.size.height;
        Class eaglClass = objc_getClass("EAGLContext");
        if (eaglClass) {
            MSHookMessageEx(eaglClass, @selector(presentRenderbuffer:),
                            (IMP)&hook_EAGLContext_presentRenderbuffer,
                            (IMP *)&orig_EAGLContext_presentRenderbuffer);
            NSLog(@"[Cheat] Hooked EAGLContext");
        }
        MSHookMessageEx(objc_getClass("UIApplication"), @selector(sendEvent:),
                        (IMP)&hook_UIApplication_sendEvent,
                        (IMP *)&orig_UIApplication_sendEvent);
        NSLog(@"[Cheat] Cheat loaded. Volume Down to toggle.");
    }
}
