CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra -D_GNU_SOURCE
LDFLAGS ?= -pthread

SRCS = main.c v4l2_sink.c procedural.c pipe_worker.c hw.c ipc.c
OBJS = $(SRCS:.c=.o)
TARGET = vcamd

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) -o $@ $(LDFLAGS)

%.o: %.c common.h
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(TARGET)

.PHONY: all clean
