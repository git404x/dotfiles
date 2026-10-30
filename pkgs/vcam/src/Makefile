CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra -D_GNU_SOURCE
LDFLAGS ?= -pthread

DAEMON_SRCS = main.c v4l2_sink.c procedural.c pipe_worker.c hw.c ipc.c
DAEMON_OBJS = $(DAEMON_SRCS:.c=.o)
DAEMON_TARGET = vcamd

WEB_SRCS = web.c
WEB_OBJS = $(WEB_SRCS:.c=.o)
WEB_TARGET = vcam-web

TARGETS = $(DAEMON_TARGET) $(WEB_TARGET)

all: $(TARGETS)

$(DAEMON_TARGET): $(DAEMON_OBJS)
	$(CC) $(DAEMON_OBJS) -o $@ $(LDFLAGS)

$(WEB_TARGET): $(WEB_OBJS)
	$(CC) $(WEB_OBJS) -o $@

%.o: %.c common.h
	$(CC) $(CFLAGS) -c $< -o $@

web.o: web.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(DAEMON_OBJS) $(WEB_OBJS) $(TARGETS)

.PHONY: all clean
