#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <ctype.h>

#define DRIVER_PATH "/sys/bus/usb/drivers/uvcvideo"

/* validate usb bus id string to prevent path traversal or invalid input */
static int is_valid_bus_id(const char *id) {
    if (!id || *id == '\0' || strlen(id) > 64) return 0;
    for (const char *p = id; *p; p++) {
        if (!isalnum((unsigned char)*p) && *p != '-' && *p != '.' && *p != ':') {
            return 0;
        }
    }
    return 1;
}

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "usage: vcam-hw <bind <id> | unbind <id> | modprobe>\n");
        return 1;
    }

    if (strcmp(argv[1], "bind") == 0 || strcmp(argv[1], "unbind") == 0) {
        if (argc < 3 || !is_valid_bus_id(argv[2])) {
            fprintf(stderr, "vcam-hw: invalid or missing device bus id\n");
            return 1;
        }

        char path[256];
        snprintf(path, sizeof(path), "%s/%s", DRIVER_PATH, argv[1]);

        int fd = open(path, O_WRONLY);
        if (fd < 0) {
            perror("vcam-hw: open sysfs driver endpoint");
            return 1;
        }

        ssize_t len = (ssize_t)strlen(argv[2]);
        if (write(fd, argv[2], len) != len) {
            perror("vcam-hw: write sysfs driver endpoint");
            close(fd);
            return 1;
        }
        close(fd);
        return 0;
    } else if (strcmp(argv[1], "modprobe") == 0) {
        execlp("modprobe", "modprobe", "uvcvideo", NULL);
        perror("vcam-hw: exec modprobe");
        return 1;
    }

    fprintf(stderr, "vcam-hw: unknown action '%s'\n", argv[1]);
    return 1;
}
