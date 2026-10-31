CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra -D_GNU_SOURCE
LDFLAGS ?= -pthread

DAEMON_SRCS = main.c v4l2_sink.c procedural.c pipe_worker.c hw.c ipc.c
DAEMON_OBJS = $(DAEMON_SRCS:.c=.o)
DAEMON_TARGET = vcamd

TEST_SRCS = test_bench.c web_server.c
TEST_OBJS = $(TEST_SRCS:.c=.o)
TEST_TARGET = vcam-test

TARGETS = $(DAEMON_TARGET) $(TEST_TARGET)

all: $(TARGETS)

web_assets.h: ../index.html
	@echo "generating web_assets.h from $<..."
	@echo "/* auto-generated from ../index.html */" > $@
	@echo "#ifndef VCAM_WEB_ASSETS_H" >> $@
	@echo "#define VCAM_WEB_ASSETS_H" >> $@
	@echo "#include <stddef.h>" >> $@
	@echo "static const unsigned char g_index_html[] = {" >> $@
	@od -v -t x1 $< | awk '{for(i=2;i<=NF;i++) printf "0x%s, ", $$i; printf "\n"}' >> $@
	@echo "0x00 };" >> $@
	@echo "static const size_t g_index_html_len = sizeof(g_index_html) - 1;" >> $@
	@echo "#endif /* VCAM_WEB_ASSETS_H */" >> $@

$(DAEMON_TARGET): $(DAEMON_OBJS)
	$(CC) $(DAEMON_OBJS) -o $@ $(LDFLAGS)

$(TEST_TARGET): $(TEST_OBJS)
	$(CC) $(TEST_OBJS) -o $@

%.o: %.c common.h
	$(CC) $(CFLAGS) -c $< -o $@

web_server.o: web_server.c web_server.h
	$(CC) $(CFLAGS) -c $< -o $@

test_bench.o: test_bench.c web_server.h web_assets.h
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(DAEMON_OBJS) $(TEST_OBJS) $(TARGETS) web_assets.h

.PHONY: all clean
