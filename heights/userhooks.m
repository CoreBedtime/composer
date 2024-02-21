//
//  userhooks.c
//  menuheights
//
//  Created by knives on 2/5/24.
//


#include <Foundation/Foundation.h>
#include <ImageIO/ImageIO.h>
#include <objc/message.h>
#include <pwd.h>
#include <dlfcn.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <sys/_types/_null.h>
#include <sys/types.h>
#include <unistd.h>
#include <string.h>
#include <IOSurface/IOSurface.h>
#include <CoreFoundation/CoreFoundation.h>
#include <CoreGraphics/CoreGraphics.h>
#include <objc/objc.h>
#include <objc/runtime.h>

#include <AppKit/AppKit.h>
#include <QuartzCore/QuartzCore.h>

#include "symrez/symrez.h"
#include "heights.h"
#include "frida-gum.h"

CGImageRef ImageFromFile(const char *filePath) 
{
    CGDataProviderRef dataProvider = CGDataProviderCreateWithFilename(filePath);
    return CGImageCreateWithPNGDataProvider(dataProvider, NULL, NO, kCGRenderingIntentDefault);
}

#pragma mark - menubar


void (*MenubarLayersOld)();
void MenubarLayersNew(void *param_1, bool param_2)
{
    MenubarLayersOld(param_1, param_2);

    if (MenubarGraphic)
    {
        // Fetching the class of the layer object
        CALayer * layer_one = *(id *)((uintptr_t)param_1 + 0x10);
        CALayer * layer_two = *(id *)((uintptr_t)param_1 + 0x18);

        layer_one.contents = ImageFromFile("/Library/wsfun/menubar.png");
        layer_two.contents = ImageFromFile("/Library/wsfun/menubar.png");
    }
}


CGRect (*HeightOld)();
CGRect HeightNew()
{
    CGRect orig = HeightOld();
    orig.size.height = __height;
    return orig;
}

void ClientRenderHeightNew(int did, int * height)
{
    *height = __height;
    return;
}

#pragma mark - shadows

struct ServerShadow {
    IOSurfaceRef surface;
    // Other members...
};

// to render shadow properly in correct color
void SwapRedBlue(IOSurfaceRef surface)
{
    if (!surface) 
    {
        // Handle null surface
        return;
    }

    // Get surface properties
    uint32_t width = (uint32_t)IOSurfaceGetWidth(surface);
    uint32_t height = (uint32_t)IOSurfaceGetHeight(surface);
    size_t bytesPerElement = IOSurfaceGetBytesPerElement(surface);
    size_t bytesPerRow = IOSurfaceGetBytesPerRow(surface);

    // Get base address of the surface
    void *baseAddress = IOSurfaceGetBaseAddress(surface);

    // Iterate through each pixel
    for (uint32_t y = 0; y < height; y++) 
    {
        for (uint32_t x = 0; x < width; x++) 
        {
            // Calculate the offset for the current pixel
            size_t offset = y * bytesPerRow + x * bytesPerElement;
            
            // Swap red and blue channels
            uint8_t *pixel = ((uint8_t *)baseAddress) + offset;
            uint8_t temp = pixel[0];  // Store red channel temporarily
            pixel[0] = pixel[2];      // Red channel becomes blue
            pixel[2] = temp;          // Blue channel becomes red
        }
    }
}

long (*ServerShadowSurfaceOld)();
long ServerShadowSurfaceNew(void * shadow_ptr /* WSShadow:: */, void * param_1,void * param_2)
{
    // Create a new iOSurface
    long k = ServerShadowSurfaceOld(shadow_ptr, param_1, param_2);
    struct ServerShadow * shadow = (struct ServerShadow *)shadow_ptr;
    
    IOSurfaceLock(shadow->surface, 0, NULL);
    int width = IOSurfaceGetWidth(shadow->surface);
    int height = IOSurfaceGetHeight(shadow->surface);

    // Obtains the real window rect (most system windows)
    CGRect real_window_rect = CGRectInset(CGRectMake(0, 0, width, height), 34, 26);
    real_window_rect.origin.y += 16;
    real_window_rect.size.height -= 16;

    // Create a bitmap context for the surface
    CGContextRef context = CGBitmapContextCreate(IOSurfaceGetBaseAddress(shadow->surface),
                                                 width,
                                                 height,
                                                 8, // bits per component
                                                 IOSurfaceGetBytesPerRow(shadow->surface),
                                                 CGColorSpaceCreateDeviceRGB(),
                                                 kCGImageAlphaPremultipliedLast);


    if (WindowHideShadow) // clear the surface
    {
        CGContextClearRect(context, CGRectMake(0, 0, width, height));
    }

    if (WindowDecorations)
    {
        CGContextSetRGBFillColor(context, 255.0 / 255, 255.0 / 255, 255.0 / 255, 1.0); // shadow color
        CGContextFillRect(context, CGRectInset(real_window_rect, -12, -12));
        
        CGContextSetRGBFillColor(context, 48.0 / 255, 138.0 / 255, 255.0 / 255, 1.0); // shadow color
        CGContextFillRect(context, CGRectInset(real_window_rect, -6, -6));
        

        CGContextClearRect(context, real_window_rect); // final clear of the REAL window rect.
    }
    
    CGContextFlush(context);
    CGContextRelease(context);

    SwapRedBlue(shadow->surface);
    // Return the iOSurface
    IOSurfaceUnlock(shadow->surface, 0, 0);

    return k;
}


CGError (*ServerSetHasActiveShadowOld)();
CGError ServerSetHasActiveShadowNew(long param_1,uint param_2)
{
    return ServerSetHasActiveShadowOld(param_1, 0); /* 
                                                    setting to zero disables the two states, 
                                                    which also makes drawing easier
                                                    as everything shadow isnt moving.
                                                    */
}

void *BadCornerMask(void *inone, void * intwo)
{
    return NULL;
}

id (*BackedWindowLayerOld)();
id BackedWindowLayerNew(void *inone, void * intwo)
{
    id k = BackedWindowLayerOld();
    ((CALayer *)k).cornerRadius = 0;
    return k;
}

void (*HideCornerRimOld)();
void HideCornerRimNew(id self, void * sel)
{
    /*
    This code is very specific, and 
    why does it have to be done this way? idk.
    */
    ((NSView*)self).alphaValue = 0;
    HideCornerRimOld(self, sel);
}

id (*CopyColorOld)();

@interface CUIShapeEffectPreset : NSObject
    @property id effectName;
    -(id)debugDescription;
    -(void)addColorValueRed:(unsigned int)arg1 green:(unsigned int)arg2 blue:(unsigned int)arg3 forParameter:(unsigned int)arg4 withNewEffectType:(unsigned int)arg5;
    -(void)addColorFillWithRed:(unsigned int)arg1 green:(unsigned int)arg2 blue:(unsigned int)arg3 opacity:(double)arg4 blendMode:(unsigned int)arg5 tintable:(BOOL)arg6;
    -(void)appendColorValueRed:(unsigned int)arg1 green:(unsigned int)arg2 blue:(unsigned int)arg3 forParameter:(unsigned int)arg4 withEffectType:(unsigned int)arg5;
    - (void)addGradientFillWithTopColorRed:(unsigned int)arg1 green:(unsigned int)arg2 blue:(unsigned int)arg3 bottomColorRed:(unsigned int)arg4 green:(unsigned int)arg5 blue:(unsigned int)arg6 opacity:(double)arg7 blendMode:(unsigned int)arg8;
    -(unsigned int)effectTypeAtIndex:(unsigned long long)arg1;
    - (unsigned long long)effectCount;
    - (unsigned long long)_parameterCount;
    - (void)addOutputOpacityWithOpacity:(double)arg1;
    - (void)addShapeOpacityWithOpacity:(double)arg1;
@end

id CopyColorNew(id self, void * sel)
{
    CUIShapeEffectPreset * k = CopyColorOld(self, sel);
    CUIShapeEffectPreset *future = [objc_getClass("CUIShapeEffectPreset") new];

    NSCharacterSet *trim = [NSCharacterSet characterSetWithCharactersInString:@"-: ."];
    NSString *result = [[[[(id)self name] lowercaseString] componentsSeparatedByCharactersInSet:trim] componentsJoinedByString:@""];

    int r, g, b, a;

    if ([result isEqual:@"menubartext"])
    {
        r = MenubarTextRGBA[0]; g = MenubarTextRGBA[1]; b = MenubarTextRGBA[2]; a = MenubarTextRGBA[3];
    } 
    else if ([result isEqual:@"menubarimage"])
    {
        r = MenubarAppleRGBA[0]; g = MenubarAppleRGBA[1]; b = MenubarAppleRGBA[2]; a = MenubarAppleRGBA[3];
    }
    else {
        return k;
    }

    
    [future addColorFillWithRed:r green:g blue:b opacity:a blendMode:kCGBlendModeNormal tintable:0];
    [future addShapeOpacityWithOpacity:1];
    [future addOutputOpacityWithOpacity:1];

    return future;
}

long (*BackdropOld)();
long BackdropNew(float param_1, long param_2)
{
    int k, l;
    l = param_1;
    k = BackdropOld(param_1, param_2);

    __dbg("k %d, l %d", k, l);

    return k;
}

GumInterceptor *magic;
void (*GumInterceptorReplaceFunc)(GumInterceptor * self, gpointer function_address, gpointer replacement_function, gpointer replacement_data, gpointer * original_function);
void *(*GumModuleFindExportByNameFunc)(const gchar * module_name, const gchar * symbol_name);
void (*GumInterceptorBeginTransactionFunc)(GumInterceptor * self);
void (*GumInterceptorEndTransactionFunc)(GumInterceptor * self);

void ClientHook(void * func, void * new, void ** old)
{
    GumInterceptorBeginTransactionFunc(magic);
    GumInterceptorReplaceFunc(magic, (gpointer)func, new, NULL, old);
    GumInterceptorEndTransactionFunc(magic);
}

void InstantiateClientHooks(GumInterceptor *interceptor)
{
    // Setup hooking
    magic = interceptor;
    void *hooking = dlopen("/usr/local/bin/ammonia/fridagum.dylib", RTLD_NOW | RTLD_GLOBAL);
    GumInterceptorReplaceFunc = dlsym(hooking, "gum_interceptor_replace");
    GumModuleFindExportByNameFunc = dlsym(hooking, "gum_module_find_export_by_name");
    GumInterceptorBeginTransactionFunc = dlsym(hooking, "gum_interceptor_begin_transaction");
    GumInterceptorEndTransactionFunc = dlsym(hooking, "gum_interceptor_end_transaction");

    symrez_t skylight = symrez_new("SkyLight");
    
    if (skylight != NULL)
    { 
        // Hooks the shadow image, and properties
        ClientHook(sr_resolve_symbol(skylight, "_WSWindowSetHasActiveShadow"), ServerSetHasActiveShadowNew, &ServerSetHasActiveShadowOld); 
        ClientHook(sr_resolve_symbol(skylight, "__ZN8WSShadowC1EP11__IOSurface19WSShadowDescription"), ServerShadowSurfaceNew, &ServerShadowSurfaceOld); 

        // Menubar
        ClientHook(sr_resolve_symbol(skylight, "__ZL40configure_menu_bar_layers_for_backgroundP17PKGMenuBarContextb"), MenubarLayersNew, &MenubarLayersOld);
        ClientHook(sr_resolve_symbol(skylight, "__ZL25menu_bar_bounds_for_spaceP19PKGManagedMenuSpace"), HeightNew, &HeightOld); 
        ClientHook(sr_resolve_symbol(skylight, "_SLSGetDisplayMenubarHeight"), ClientRenderHeightNew, NULL); 

        // Window Drag
        ClientHook(sr_resolve_symbol(skylight, "_set_bleed_for_backdrop_array"), BackdropNew, &BackdropOld); // scary one
    }

    // Do magic with objc runtime + frida

    if (WindowSharpCorners)
    {
        Class _windowclass = objc_getClass("NSWindow");
            SEL _shadowselector = sel_getUid("_cornerMask");
                Method _shadowmethod = class_getInstanceMethod(_windowclass, _shadowselector);
                    IMP _shadowimp = method_getImplementation(_shadowmethod);
                        if (_shadowimp) { ClientHook(_shadowimp, (IMP)BadCornerMask, NULL); }
        Class _rimclass = objc_getClass("_NSTitlebarDecorationView");
            SEL _rimselector = sel_getUid("layout");
                Method _rimwmethod = class_getInstanceMethod(_rimclass, _rimselector);
                    IMP _rimimp = method_getImplementation(_rimwmethod);
                        if (_rimimp) { ClientHook(_rimimp, (IMP)HideCornerRimNew, &HideCornerRimOld); }
    }

    Class _colorclass = objc_getClass("_CUIThemeEffectRendition");
        SEL _colorselector = sel_getUid("effectPreset");
            Method _colormethod = class_getInstanceMethod(_colorclass, _colorselector);
                IMP _colorimp = method_getImplementation(_colormethod);
                    if (_colorimp) { ClientHook(_colorimp, (IMP)CopyColorNew, &CopyColorOld); }
}