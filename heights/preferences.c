//
//  preferences.c
//  menuheights
//
//  Created by knives on 2/20/24.
//
//  This will need to be redone at some point.

#include "heights.h"
#include "toml/toml.h"
#include <string.h>

int MenubarHeight = 50;
bool MenubarGraphic = true;
bool MenubarHide = false;

int MenubarAppleRGBA[4] = {0, 0, 0, 255};
int MenubarTextRGBA[4] = {255, 255, 255, 255};

int WindowIndwardWidth = 0;
int WindowOutwardWidth = 12;
bool WindowSharpCorners = true;
bool WindowHideShadow = false;
bool WindowDecorations = true;

bool ParseColorArray(toml_array_t *arr, int *rgba) 
{
    if (rgba)
    {
        for (int i = 0; i < 4; ++i) 
        {
            toml_datum_t val = toml_int_at(arr, i);
            if (!val.ok) 
            {
                return false;
            }
            rgba[i] = val.u.i;
        }
        return true;
    }
    return false;
}


void InstantiateGlobalSettings(void) 
{
    FILE* fp;
    char errbuf[200];

    // Read and parse toml file
    fp = fopen("/Library/wsfun/config.ini", "r");
    if (!fp) 
    {
        __dbg("cannot open /Library/wsfun/config.ini - %s\n", strerror(errno));
        return;
    }

    toml_table_t* conf = toml_parse_file(fp, errbuf, sizeof(errbuf));
    fclose(fp);

    if (!conf) 
    {
        __dbg("cannot parse - %s\n", errbuf);
        return;
    }

    toml_table_t* menubar = toml_table_in(conf, "menubar");
    if (menubar) 
    {
        toml_datum_t height = toml_int_in(menubar, "height");
        if (height.ok) { MenubarHeight = height.u.i; }

        toml_datum_t backgroundPath = toml_bool_in(menubar, "enable_png");
        if (backgroundPath.ok) { MenubarGraphic = backgroundPath.u.b; }

        toml_datum_t hide_menubar = toml_bool_in(menubar, "hide_menubar");
        if (hide_menubar.ok) { MenubarHide = hide_menubar.u.b; }

        toml_array_t *appleRGBA = toml_array_in(menubar, "apple_rgba");
        if (appleRGBA) { ParseColorArray(appleRGBA, MenubarAppleRGBA); }

        toml_array_t *textRGBA = toml_array_in(menubar, "text_rgba");
        if (textRGBA) { ParseColorArray(textRGBA, MenubarTextRGBA); }
    }

    toml_table_t* window = toml_table_in(conf, "window");
    if (window) 
    {
        toml_datum_t sharp = toml_bool_in(window, "sharp_corner");
        if (sharp.ok) { WindowSharpCorners = sharp.u.b; }
        
        toml_datum_t shadow = toml_bool_in(window, "hide_shadow");
        if (shadow.ok) { WindowHideShadow = shadow.u.b;  }
        
        toml_datum_t decor = toml_bool_in(window, "decor");
        if (decor.ok) { WindowDecorations = decor.u.b; }

        toml_datum_t width = toml_int_in(window, "decor_width");
        if (width.ok) { WindowOutwardWidth = width.u.i; }

        toml_datum_t inward = toml_int_in(window, "decor_width_in");
        if (inward.ok) { WindowIndwardWidth = inward.u.i; }
    }

cleanup:
    toml_free(conf);
    return;
}