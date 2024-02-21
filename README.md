<div style="display: flex; flex-direction: column; align-items: center;">
    <img src=".readme/composerlogo.png" alt="Logo" width="100"/>
    <h1 style="font-size: 34px; text-decoration: none;">Composer</h1>
    <p style="font-size: 16px; margin-top: 10px; text-decoration: none;">OSX Extended Desktop</p>
</div>


# What is this?
The "Composer" serves as an augmentation to the OSX Desktop Environment. The primary objective is to grant users more control over the aesthetics and even functionality of their OSX desktop experience.

# How to install? (requires XCode)
- Turn off SIP
    - Restart your computer in Recovery mode.
    - Launch Terminal from the Utilities menu.
    - Run the command `csrutil disable`. (Warning can be ignored)
    - Restart your computer.
- Turn on arm64e preview ABI (Apple Silicon only)
- Install the [Ammonia](https://github.com/CoreBedtime/ammonia) tweak loader 
    - Run `git clone https://github.com/CoreBedtime/ammonia.git`
    - Run `cd ammonia && ./setup_frida.sh && sudo ./install.sh`
- Run `make clean && make -j8 && sudo pkill -9 WindowServer`
- Enjoy the magic.

# How does it work?
Its actually pretty simple... 
We:
- Resolve unexported symbols using the [libSymRez](https://github.com/jslegendre/libSymRez.git) library, allowing the interception of "secret" functions within the macOS WindowServer (among other places). 
- Initialize C and C++ function hooks using the [Frida Gum DevKit](https://github.com/frida/frida-gum) and Objective-C runtime.
- Profit!

# Configuration...
> **Note**
> Configuration file location is a bit peculiar due to the macOS sandboxing system and the way it determines which programs can access which files. The chosen directory for config is `/Library/wsfun/`. This way, all programs (and most importantly windowserver) can access config data.

Example Config File:
```ini
[menubar]
height = 55
enable_png = true
apple_rgba = [0,0,0,255,255]
text_rgba = [255,255,255,255]

[window]
sharp_corner = true
hide_shadow = false
decor = true
```

# Where is this going?
Preferably, reaching a level of customization akin to the diversity offered by custom shells on Windows and the extensive desktop options available on Linux. Imagine a world where macOS users have the freedom to tailor most aspects of their desktop environment to suit their unique preferences, just like their counterparts on other operating systems.
