CC ?= gcc
CFLAGS ?= -Wall -Wextra -O2 -std=c11
PKG_CONFIG ?= pkg-config

GST_CFLAGS := $(shell $(PKG_CONFIG) --cflags gstreamer-1.0 glib-2.0)
GST_LIBS := $(shell $(PKG_CONFIG) --libs gstreamer-1.0 glib-2.0)

SRCS = main.c engine.c effects.c hw.c ipc.c
OBJS = $(SRCS:.c=.o)
TARGET = vcamd

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) -o $(TARGET) $(GST_LIBS)

%.o: %.c common.h
	$(CC) $(CFLAGS) $(GST_CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(TARGET)

.PHONY: all clean
