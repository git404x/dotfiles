CC ?= gcc
PKG_CONFIG ?= pkg-config
CFLAGS ?= -O2 -Wall -Wextra
TARGET = vcamd

GST_CFLAGS := $(shell $(PKG_CONFIG) --cflags gstreamer-1.0 glib-2.0)
GST_LIBS := $(shell $(PKG_CONFIG) --libs gstreamer-1.0 glib-2.0)

all: $(TARGET)

$(TARGET): vcamd.c
	$(CC) $(CFLAGS) $(GST_CFLAGS) vcamd.c $(GST_LIBS) -o $(TARGET)

clean:
	rm -f $(TARGET)

.PHONY: all clean
