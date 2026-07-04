// ============================================================
// Standoff2 Cheat v2.0 — Gothbreach
// Platform: iOS 18 (arm64) | Game: Standoff2 0.39.1 f1
// Features: ESP, Wallhack, No Recoil, ImGui-style menu
// Toggle: Volume Down button
// ============================================================
#import <OpenGLES/ES1/gl.h>
#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <mach/mach.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <substrate.h>
#import "imgui/imgui.h"

// ============================================================
// OFFSETS — Standoff2 0.39.1 f1 (верифицировано через dump.cs)
// ============================================================
#define OFF_DWLOCALPLAYER   0x18AC0C8   // LocalPlayer pointer in data section
#define OFF_DWENTITYLIST    0x18AD0D8   // EntityList pointer in data section
#define OFF_DWVIEWMATRIX    0x11A210    // ViewMatrix in data section

#define OFF_M_IHEALTH       0x5C        // int health
#define OFF_M_ITEAMNUM      0xA0        // int team number
#define OFF_M_VECORIGIN     0x44        // vec3 origin
#define OFF_M_VECVIEWOFFSET 0x108       // vec3 view offset
#define OFF_M_AIMPUNCHANGLE 0x303C      // vec3 aim punch angle
#define OFF_M_VIEWPUNCH     0x12704     // vec3 view punch
#define OFF_M_BONE          0x10C       // bone matrix pointer
#define OFF_M_BSPOTTED      0x104       // byte/bool spotted (m_fFlags offset used as spotted)

#define ENTITY_SIZE         0x10        // pointer size in entity list
#define ENTITY_INDEX        0x8         // entity index offset
#define MAX_PLAYERS         32

// ============================================================
// CHEAT STATE
// ============================================================
static BOOL g_espEnabled       = YES;
static BOOL g_wallhackEnabled  = YES;
static BOOL g_noRecoilEnabled  = YES;
static BOOL g_menuVisible      = NO;

static mach_port_t    g_taskPort     = MACH_PORT_NULL;
static uintptr_t      g_baseAddress  = 0;
static uintptr_t      g_localPlayerPtr = 0;

// ImGui context
static ImGuiContext   g_imgui;
static BOOL           g_imguiInitialized = NO;

// Screen dimensions (cached)
static int g_screenW = 0;
static int g_screenH = 0;

// ============================================================
// MEMORY HELPERS (vm_read/vm_write via mach kernel)
// ============================================================
static uintptr_t findBaseAddress(void) {
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name) {
            // Ищем исполняемый образ игры (не динамические библиотеки)
            if (strstr(name, "/Standoff2") && !strstr(name, ".dylib")) {
                return (uintptr_t)_dyld_get_image_vmaddr_slide(i);
            }
        }
    }
    // Fallback: любой образ с именем Standoff2
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

static float memReadFloat(uintptr_t addr) {
    float val = 0;
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
// VECTOR / MATRIX MATH
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
// ESP — OpenGL ES overlay rendering
// ============================================================
static void drawESPBox(float x, float y, float w, float h, uint32_t color) {
    GLfloat verts[] = { x, y, x+w, y, x+w, y+h, x, y+h };
    glVertexPointer(2, GL_FLOAT, 0, verts);
    glEnableClientState(GL_VERTEX_ARRAY);
    glColor4f((color>>0)&0xFF/255.f, (color>>8)&0xFF/255.f,
              (color>>16)&0xFF/255.f, (color>>24)&0xFF/255.f);
    glDrawArrays(GL_LINE_LOOP, 0, 4);
    glDisableClientState(GL_VERTEX_ARRAY);
}

static void drawESPFilledRect(float x, float y, float w, float h, uint32_t color) {
    GLfloat verts[] = { x, y, x+w, y, x+w, y+h, x, y+h };
    GLubyte idx[] = { 0, 1, 2, 0, 2, 3 };
    glVertexPointer(2, GL_FLOAT, 0, verts);
    glEnableClientState(GL_VERTEX_ARRAY);
    glColor4f((color>>0)&0xFF/255.f, (color>>8)&0xFF/255.f,
              (color>>16)&0xFF/255.f, (color>>24)&0xFF/255.f);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, idx);
    glDisableClientState(GL_VERTEX_ARRAY);
}

static void drawESPLine(float x1, float y1, float x2, float y2, uint32_t color) {
    GLfloat verts[] = { x1, y1, x2, y2 };
    glVertexPointer(2, GL_FLOAT, 0, verts);
    glEnableClientState(GL_VERTEX_ARRAY);
    glColor4f((color>>0)&0xFF/255.f, (color>>8)&0xFF/255.f,
              (color>>16)&0xFF/255.f, (color>>24)&0xFF/255.f);
    glDrawArrays(GL_LINES, 0, 2);
    glDisableClientState(GL_VERTEX_ARRAY);
}

// ============================================================
// HACK LOGIC
// ============================================================
static void runWallhack(void) {
    if (!g_wallhackEnabled || !g_baseAddress) return;

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

        // m_bSpotted = 1 (через m_fFlags offset)
        int spotted = 1;
        memWrite(entityPtr + OFF_M_BSPOTTED, &spotted, sizeof(spotted));
    }
}

static void runNoRecoil(void) {
    if (!g_noRecoilEnabled || !g_baseAddress) return;

    uintptr_t localPlayer = memReadPtr(g_baseAddress + OFF_DWLOCALPLAYER);
    if (!localPlayer) return;

    // Обнуление aimPunchAngle (3 float)
    float zero[3] = { 0.0f, 0.0f, 0.0f };
    memWrite(localPlayer + OFF_M_AIMPUNCHANGLE, zero, sizeof(zero));

    // Обнуление viewPunch (3 float)
    memWrite(localPlayer + OFF_M_VIEWPUNCH, zero, sizeof(zero));
}

static void runESP(void) {
    if (!g_espEnabled || !g_baseAddress) return;

    uintptr_t entityListBase = memReadPtr(g_baseAddress + OFF_DWENTITYLIST);
    if (!entityListBase) return;

    uintptr_t localPlayer = memReadPtr(g_baseAddress + OFF_DWLOCALPLAYER);
    if (!localPlayer) return;

    // ViewMatrix
    matrix4x4_t viewMatrix;
    if (!memRead(g_baseAddress + OFF_DWVIEWMATRIX, &viewMatrix, sizeof(viewMatrix))) return;

    int localTeam = memReadInt(localPlayer + OFF_M_ITEAMNUM);

    glPushAttrib(GL_ALL_ATTRIB_BITS);
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

        // Позиция (ноги)
        vec3_t origin;
        memRead(entityPtr + OFF_M_VECORIGIN, &origin, sizeof(origin));

        // Позиция головы через viewOffset + origin
        vec3_t viewOffset;
        memRead(entityPtr + OFF_M_VECVIEWOFFSET, &viewOffset, sizeof(viewOffset));
        vec3_t headPos = { origin.x + viewOffset.x,
                           origin.y + viewOffset.y,
                           origin.z + viewOffset.z };

        // Project
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

        // Цвет: враг — красный
        uint32_t colorEnemy = 0xFF0000FF; // RGBA: R=255, G=0, B=0, A=255

        // Box ESP
        drawESPBox(boxX, boxY, width, height, colorEnemy);

        // Snap line (от центра низа до низа экрана)
        drawESPLine(headScreen.x, footScreen.y, headScreen.x, g_screenH, 0x40FF00FF);

        // Health bar
        float healthPct = (float)health / 100.0f;
        if (healthPct > 1.0f) healthPct = 1.0f;
        if (healthPct < 0.0f) healthPct = 0.0f;
        float barW = 4.0f;
        float barX = boxX - barW - 2.0f;
        float healthH = height * healthPct;
        float barY = boxY + (height - healthH);

        // Фон healthbar (черный)
        drawESPFilledRect(barX, boxY, barW, height, 0x00000080);
        // Health (зеленый)
        drawESPFilledRect(barX, barY, barW, healthH, 0x00FF00FF);

        // Name label (просто "ENEMY", т.к. в IL2CPP имя сложно достать)
        // Рисуем через ImGui чуть позже, иначе для текста используем drawESP
    }

    glPopMatrix();
    glMatrixMode(GL_PROJECTION);
    glPopMatrix();
    glMatrixMode(GL_MODELVIEW);
    glPopAttrib();
}

// ============================================================
// IMGUI MENU
// ============================================================
static void buildMenu(void) {
    if (!g_menuVisible) return;

    ImGui_NewFrame(&g_imgui);

    // Устанавливаем позицию мыши (при таче — по центру тача, для кнопок — не нужно)
    // В данном случае используем нажатие на чекбоксы через Volume Down клики
    // Для touch-взаимодействия можно было бы передавать координаты из UITouch,
    // но на iOS без джейлбрейка UITouch перехватить сложно.
    // Используем управление через Volume Down + touch simulation
    // Вместо мыши — используем флаг anyActive для определения клика

    ImGui_BeginWindow(&g_imgui, "Standoff2 Cheat v2.0", 300, 260);

    ImGui_Checkbox(&g_imgui, "ESP", &g_espEnabled);
    ImGui_Checkbox(&g_imgui, "Wallhack", &g_wallhackEnabled);
    ImGui_Checkbox(&g_imgui, "No Recoil", &g_noRecoilEnabled);

    ImGui_Separator(&g_imgui);

    // Показываем статус
    char status[128];
    snprintf(status, sizeof(status), "ESP: %s  WH: %s  NR: %s",
             g_espEnabled ? "ON" : "OFF",
             g_wallhackEnabled ? "ON" : "OFF",
             g_noRecoilEnabled ? "ON" : "OFF");
    ImGui_Label(&g_imgui, status);

    ImGui_Separator(&g_imgui);

    ImGui_Label(&g_imgui, "Volume Down: Toggle Menu");
    ImGui_Label(&g_imgui, "Volume Up: Cycle Functions");
    ImGui_Label(&g_imgui, "(when menu is open)");

    ImGui_EndWindow(&g_imgui);

    ImGui_Render(&g_imgui);
}

// ============================================================
// VOLUME BUTTON HANDLER (IOKit HID events)
// ============================================================
// На iOS 18 кнопки громкости генерируют UIEvent UIEventTypePresses с
// UIKeyInputLeftArrow (Volume Down) и UIKeyInputRightArrow (Volume Up) на некоторых устройствах,
// или же UIPressTypeDownArrow/UIPressTypeUpArrow.
// На iPhone 15 (iOS 18) используем UIPressTypeDownArrow/UIPressTypeUpArrow.

// Хук на sendEvent: для перехвата нажатий кнопок громкости
static void (*orig_UIApplication_sendEvent)(id, SEL, UIEvent *);
static void hook_UIApplication_sendEvent(id self, SEL _cmd, UIEvent *event) {
    orig_UIApplication_sendEvent(self, _cmd, event);

    if (event.type == UIEventTypePresses) {
        NSSet *presses = [event allPresses];
        for (UIPress *press in presses) {
            // Volume Down: 0x1F (UIKeyInputLeftArrow) или UIPressTypeDownArrow
            BOOL isVolDown = NO;
            BOOL isVolUp = NO;

            // Проверяем через keyCommands (iOS 17+)
            if ([press respondsToSelector:@selector(key)]) {
                NSString *key = [press valueForKey:@"key"];
                if ([key isEqualToString:UIKeyInputLeftArrow]) {
                    isVolDown = YES;
                } else if ([key isEqualToString:UIKeyInputRightArrow]) {
                    isVolUp = YES;
                }
            } else {
                // Fallback для старых iOS
                if (press.type == UIPressTypeDownArrow) {
                    isVolDown = YES;
                } else if (press.type == UIPressTypeUpArrow) {
                    isVolUp = YES;
                }
            }

            if (press.phase != UIPressPhaseBegan) continue;

            if (isVolDown) {
                // Volume Down: Toggle menu
                g_menuVisible = !g_menuVisible;
                NSLog(@"[Cheat] Menu toggled: %d", g_menuVisible);
            } else if (isVolUp) {
                // Volume Up: Cycle current feature toggle (когда меню открыто)
                if (g_menuVisible) {
                    // Переключаем: ESP -> Wallhack -> NoRecoil -> ESP
                    if (g_espEnabled) {
                        g_espEnabled = NO;
                        g_wallhackEnabled = YES;
                    } else if (g_wallhackEnabled) {
                        g_wallhackEnabled = NO;
                        g_noRecoilEnabled = YES;
                    } else if (g_noRecoilEnabled) {
                        g_noRecoilEnabled = NO;
                    } else {
                        g_espEnabled = YES;
                        g_wallhackEnabled = YES;
                        g_noRecoilEnabled = YES;
                    }
                    NSLog(@"[Cheat] Cycle features: ESP=%d WH=%d NR=%d",
                          g_espEnabled, g_wallhackEnabled, g_noRecoilEnabled);
                } else {
                    // Если меню закрыто — всё включаем/выключаем
                    BOOL anyOn = (g_espEnabled || g_wallhackEnabled || g_noRecoilEnabled);
                    g_espEnabled = !anyOn;
                    g_wallhackEnabled = !anyOn;
                    g_noRecoilEnabled = !anyOn;
                }
            }
        }
    }

    // Также перехватываем UIEventSubtypeRemoteControlVolumeDown/Up (запасной вариант)
    if (event.type == UIEventTypeRemoteControl) {
        if (event.subtype == UIEventSubtypeRemoteControlTogglePlayPause) {
            g_menuVisible = !g_menuVisible;
        }
    }
}

// ============================================================
// OPENGL ES RENDER HOOK
// ============================================================
// Хукаем EAGLContext presentRenderbuffer: для рендеринга оверлея
static void (*orig_EAGLContext_presentRenderbuffer)(id, SEL, GLint);
static void hook_EAGLContext_presentRenderbuffer(id self, SEL _cmd, GLint renderbuffer) {
    // One-time init
    static BOOL initialized = NO;
    if (!initialized) {
        g_taskPort = mach_task_self();
        g_baseAddress = findBaseAddress();
        if (g_baseAddress) {
            g_localPlayerPtr = memReadPtr(g_baseAddress + OFF_DWLOCALPLAYER);
        }
        NSLog(@"[Cheat] Base: 0x%lx | LocalPlayer: 0x%lx", (unsigned long)g_baseAddress,
              (unsigned long)g_localPlayerPtr);

        // Cache screen size
        UIScreen *screen = [UIScreen mainScreen];
        CGFloat scale = screen.scale;
        CGSize nativeSize = screen.nativeBounds.size;
        g_screenW = (int)nativeSize.width;
        g_screenH = (int)nativeSize.height;

        // Init ImGui
        ImGui_Init(&g_imgui, g_screenW, g_screenH, scale);

        initialized = YES;
    }

    // Call original first (важно для EAGLContext)
    orig_EAGLContext_presentRenderbuffer(self, _cmd, renderbuffer);

    if (!g_baseAddress) return;

    // Запускаем ESP через OpenGL
    runESP();

    // Wallhack + NoRecoil через память (не зависят от рендера)
    runWallhack();
    runNoRecoil();

    // ImGui Menu
    buildMenu();
}

// ============================================================
// APPLICATION HOOKS
// ============================================================
// Хук на UIApplication для гарантированного захвата событий кнопок громкости
// (работает в связке с sendEvent:)

// ============================================================
// CONSTRUCTOR — Theos %ctor
// ============================================================
%ctor {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSLog(@"[Cheat] =======================================");
    NSLog(@"[Cheat] Standoff2 Cheat v2.0 loading...");
    NSLog(@"[Cheat] Platform: iOS %@ arm64", [[UIDevice currentDevice] systemVersion]);
    NSLog(@"[Cheat] =======================================");

    // Get task port
    g_taskPort = mach_task_self();

    // Find base address
    g_baseAddress = findBaseAddress();
    NSLog(@"[Cheat] Game base address: 0x%lx", (unsigned long)g_baseAddress);

    if (!g_baseAddress) {
        NSLog(@"[Cheat] ERROR: Cannot find Standoff2 base address!");
        [pool release];
        return;
    }

    // Read local player
    g_localPlayerPtr = memReadPtr(g_baseAddress + OFF_DWLOCALPLAYER);
    NSLog(@"[Cheat] LocalPlayer ptr: 0x%lx", (unsigned long)g_localPlayerPtr);

    // Cache screen size (для случая если хук не сработает до первого рендера)
    if (g_screenW == 0) {
        UIScreen *screen = [UIScreen mainScreen];
        CGSize nativeSize = screen.nativeBounds.size;
        g_screenW = (int)nativeSize.width;
        g_screenH = (int)nativeSize.height;
    }

    // Хук на EAGLContext presentRenderbuffer:
    Class eaglClass = objc_getClass("EAGLContext");
    if (eaglClass) {
        MSHookMessageEx(
            eaglClass,
            @selector(presentRenderbuffer:),
            (IMP)&hook_EAGLContext_presentRenderbuffer,
            (IMP *)&orig_EAGLContext_presentRenderbuffer
        );
        NSLog(@"[Cheat] Hooked EAGLContext presentRenderbuffer:");
    } else {
        NSLog(@"[Cheat] ERROR: EAGLContext class not found!");
    }

    // Хук на UIApplication sendEvent: для кнопок громкости
    MSHookMessageEx(
        objc_getClass("UIApplication"),
        @selector(sendEvent:),
        (IMP)&hook_UIApplication_sendEvent,
        (IMP *)&orig_UIApplication_sendEvent
    );
    NSLog(@"[Cheat] Hooked UIApplication sendEvent:");

    // Инициализируем ImGui если ещё не
    if (!g_imguiInitialized && g_screenW > 0) {
        ImGui_Init(&g_imgui, g_screenW, g_screenH, [UIScreen mainScreen].scale);
        g_imguiInitialized = YES;
    }

    NSLog(@"[Cheat] Cheat loaded successfully!");
    NSLog(@"[Cheat] Volume Down = Toggle Menu");
    NSLog(@"[Cheat] Volume Up = Cycle features");

    [pool release];
}
