#include <CoreFoundation/CoreFoundation.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>

#pragma once

static inline CFNumberRef CFNUM32(int32_t num)
{
    return CFNumberCreate(NULL, kCFNumberSInt32Type, &num);
}

extern int SLSMainConnectionID();
#define __connection SLSMainConnectionID()

extern int MenubarHeight;
extern bool MenubarGraphic;
extern bool MenubarHide;

extern int MenubarAppleRGBA[4];
extern int MenubarTextRGBA[4];

extern bool WindowSharpCorners;
extern bool WindowHideShadow;
extern bool WindowDecorations;
extern int WindowOutwardWidth;

#define __height MenubarHeight

#define __homedir getpwuid(getuid())->pw_dir
#define __maintarget "WindowServer"
#define __fps (1 / 8.0)
#define __dbg(msg, ...) do { \
                            syslog(LOG_ERR, "_%s -> " msg "\n", __func__, ##__VA_ARGS__); \
                        } while (0)