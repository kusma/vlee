#pragma once

#define ARRAY_SIZE(x) (sizeof((x)) / sizeof((x)[0]))

// #define VJSYS

#define DEFAULT_FORMAT      D3DFMT_X8R8G8B8
#define DEFAULT_MULTISAMPLE D3DMULTISAMPLE_NONE;
#define DEFAULT_VSYNC       TRUE

#define NEED_STENCIL FALSE
#define MIN_VS_VERSION D3DVS_VERSION(2, 0)

#if defined(NDEBUG) && !defined(SYNC) && !defined(DUMP_VIDEO)
#define DEFAULT_FULLSCREEN 1
#else
#define DEFAULT_FULLSCREEN 0
#endif

#define DEMO_ASPECT (16.0 / 9)
#define BPM 167.0
