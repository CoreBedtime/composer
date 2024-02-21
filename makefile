CC = clang
CFLAGS = -g -Wall -Wextra -std=c11 -arch x86_64 -arch arm64 -arch arm64e
OBJCFLAGS = -Wall -Wextra -arch x86_64 -arch arm64 -arch arm64e
LDFLAGS = -dynamiclib -F/System/Library/PrivateFrameworks -framework SkyLight -framework CoreGraphics -framework Foundation -framework CoreFoundation -framework IOSurface -framework ApplicationServices -framework QuartzCore

# Get all .c and .m files in the menuheights/ directory
SOURCES = $(wildcard heights/*.c heights/*.m heights/symrez/*.c heights/toml/*.c)

# Generate corresponding .o file names
OBJECTS = $(SOURCES:.c=.o)
OBJECTS := $(OBJECTS:.m=.o)

# Library name
LIBRARY = libcomposer.dylib

# Installation directory
INSTALL_DIR = /usr/local/bin/ammonia/tweaks

all: $(LIBRARY) install

$(LIBRARY): $(OBJECTS)
	$(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@

install: $(LIBRARY)
	@mkdir -p $(INSTALL_DIR)
	@cp $(LIBRARY) $(INSTALL_DIR)/$(LIBRARY)
	@touch $(INSTALL_DIR)/$(LIBRARY).blacklist

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.m
	$(CC) $(OBJCFLAGS) -c $< -o $@

clean: uninstall
	rm -f $(OBJECTS) $(LIBRARY)

uninstall:
	rm -f $(INSTALL_DIR)/$(LIBRARY) $(INSTALL_DIR)/$(LIBRARY).blacklist
