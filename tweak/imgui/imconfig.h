//-----------------------------------------------------------------------------
// IMGUI USER CONFIG
//-----------------------------------------------------------------------------

#pragma once

//---- Define assertion handler.
//#define IM_ASSERT(_EXPR)  MyAssert(_EXPR)
//#define IM_ASSERT(_EXPR)  ((void)(_EXPR))

//---- Define attributes of all API symbols declarations, e.g. for DLL under Windows
//#define IMGUI_API __declspec( dllexport )
//#define IMGUI_API __declspec( dllimport )

//---- Don't define obsolete functions names.
//#define IMGUI_DISABLE_OBSOLETE_FUNCTIONS

//---- Don't implement default clipboard handlers.
//#define IMGUI_DISABLE_DEFAULT_CLIPBOARD_FUNCTIONS

//---- Don't implement demo window functionality.
//#define IMGUI_DISABLE_DEMO_WINDOWS

//---- Don't implement ImFormatString, ImFormatStringV, ImTextStrToUtf8, etc.
//#define IMGUI_DISABLE_FORMAT_STRING_FUNCTIONS

//---- Use 32-bit vertex indices (default is 16-bit) to allow meshes with more than 64k vertices
//#define ImDrawIdx unsigned int

//---- Use the compact font (mostly Latin glyphs), saving about 60K of data.
//#define IMGUI_USE_COMPACT_FONT

//---- Use the Mace font (for macOS), saving ~120K of data.
//#define IMGUI_USE_MACE_FONT

//---- Support for the X11 clipboard (X11 only)
//#define IMGUI_ENABLE_X11_CLIPBOARD

//---- Use the stb_printf lib to support the %s, %d, %f placeholders in ImGui::Debug.
//#define IMGUI_USE_STB_SPRINTF

//---- Use the stb_truetype rasterizer (needs stb_truetype.h)
//#define IMGUI_ENABLE_STB_TRUETYPE

//---- Use the freetype rasterizer (needs FreeType library)
//#define IMGUI_ENABLE_FREETYPE

//---- Use the FreeType library to load and rasterize fonts (needs FreeType headers)
//#define IMGUI_ENABLE_FREETYPE_LUNASVG

//---- Override the vertex types. ImDrawVert and ImDrawIdx must be POD types.
//#define ImDrawVert MyImDrawVert
//#define ImDrawIdx  unsigned short

//---- Override the ImGui namespace
//#define IMGUI_NAMESPACE MyImGui

//---- Set the memory allocator to use.
//#define IMGUI_DISABLE_DEFAULT_ALLOCATORS
//#define ImGui::MemAlloc(S)   MyAlloc(S)
//#define ImGui::MemFree(P)    MyFree(P)

//---- Use the built-in math functions (sinf, cosf, sqrtf) instead of the MSVC CRT ones.
//#define IMGUI_USE_STB_MATH

//---- Use the 32-bit version of the stb_truetype library
//#define IMGUI_USE_STB_TRUETYPE_32BIT

//---- Use the 64-bit version of the stb_truetype library
//#define IMGUI_USE_STB_TRUETYPE_64BIT

//---- Enable support for large meshes (>64k vertices)
//#define ImDrawIdx unsigned int

//---- Define custom assert for ImGui.
//#define IM_ASSERT(_EXPR)  MyAssert(_EXPR)

//---- Define custom math functions for ImGui.
//#define IMGUI_DEFINE_MATH_OPERATORS

//---- Enable support for the ImGui::IsItemDeactivated() function.
//#define IMGUI_ENABLE_IS_ITEM_DEACTIVATED

//---- Enable support for the ImGui::IsItemDeactivatedAfterEdit() function.
//#define IMGUI_ENABLE_IS_ITEM_DEACTIVATED_AFTER_EDIT

//---- Disable support for 3 or 4 channels (RGBA) images.
//#define IMGUI_DISABLE_IMAGE_SUPPORT