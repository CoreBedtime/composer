//
//  main.c
//  menuheights
//
//  Created by knives on 2/4/24.
//

#include <ApplicationServices/ApplicationServices.h>
#include <CoreGraphics/CoreGraphics.h>
#include <pwd.h>
#include <dlfcn.h>
#include <stdbool.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include "frida-gum.h"

#include "heights.h"

extern
void InstantiateClientHooks(void *);

extern
void InstantiateGlobalSettings(void);

void __attribute__((__visibility__("default"))) LoadFunction(GumInterceptor *interceptor)
{
    // if (strstr(getprogname(), __maintarget) != NULL)
    {
        InstantiateGlobalSettings();
        InstantiateClientHooks(interceptor);
    }
}
