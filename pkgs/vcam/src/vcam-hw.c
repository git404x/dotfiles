#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <dirent.h>
#include <ctype.h>
#include <limits.h>
#include <sys/wait.h>

#define DRIVER_DIR "/sys/bus/usb/drivers/uvcvideo"
#define USB_DEV_DIR "/sys/bus/usb/devices"

static int is_valid_bus_id(const char *id) {
    if (!id || *id == '\0' || strlen(id) > 64) return 0;
    for (const char *p = id; *p; p++) {
        if (!isalnum((unsigned char)*p) && *p != '-' && *p != '.' && *p != ':') {
            return 0;
        }
    }
    return 1;
}

static int str_contains_case(const char *haystack, const char *needle) {
    if (!haystack || !needle) return 0;
    size_t hlen = strlen(haystack);
    size_t nlen = strlen(needle);
    if (nlen > hlen) return 0;

    for (size_t i = 0; i <= hlen - nlen; i++) {
        size_t j = 0;
        while (j < nlen && tolower((unsigned char)haystack[i + j]) == tolower((unsigned char)needle[j])) {
            j++;
        }
        if (j == nlen) return 1;
    }
    return 0;
}

/* auto-detect primary usb camera bus id (e.g. "3-2.1") */
static int find_webcam_bus(char *out_bus, size_t max_len) {
    DIR *d = opendir(USB_DEV_DIR);
    if (!d) return -1;

    struct dirent *entry;
    char found[256] = {0};

    while ((entry = readdir(d)) != NULL) {
        if (entry->d_name[0] == '.') continue;

        /* 1. Universal USB standard: check for USB Video Class (0e / 14) interface */
        if (strchr(entry->d_name, ':')) {
            char ifclass_path[PATH_MAX];
            snprintf(ifclass_path, sizeof(ifclass_path), "%s/%s/bInterfaceClass", USB_DEV_DIR, entry->d_name);
            FILE *cf = fopen(ifclass_path, "r");
            if (cf) {
                char cls[16] = {0};
                if (fgets(cls, sizeof(cls), cf)) {
                    if (strncmp(cls, "0e", 2) == 0 || strncmp(cls, "0E", 2) == 0 || atoi(cls) == 14) {
                        snprintf(found, sizeof(found), "%s", entry->d_name);
                        char *colon = strchr(found, ':');
                        if (colon) *colon = '\0';
                        fclose(cf);
                        break;
                    }
                }
                fclose(cf);
            }
            continue;
        }

        /* 2. Fallback heuristic: check vendor id for common camera vendors (e.g. 13d3 Azurewave) */
        char vendor_path[PATH_MAX];
        snprintf(vendor_path, sizeof(vendor_path), "%s/%s/idVendor", USB_DEV_DIR, entry->d_name);
        FILE *vf = fopen(vendor_path, "r");
        if (vf) {
            char vid[16] = {0};
            if (fgets(vid, sizeof(vid), vf)) {
                if (strncmp(vid, "13d3", 4) == 0) {
                    snprintf(found, sizeof(found), "%s", entry->d_name);
                    fclose(vf);
                    break;
                }
            }
            fclose(vf);
        }

        /* 3. Fallback heuristic: check product string */
        char prod_path[PATH_MAX];
        snprintf(prod_path, sizeof(prod_path), "%s/%s/product", USB_DEV_DIR, entry->d_name);
        FILE *pf = fopen(prod_path, "r");
        if (pf) {
            char prod[128] = {0};
            if (fgets(prod, sizeof(prod), pf)) {
                if (str_contains_case(prod, "camera") || str_contains_case(prod, "webcam") || str_contains_case(prod, "uvc")) {
                    snprintf(found, sizeof(found), "%s", entry->d_name);
                    fclose(pf);
                    break;
                }
            }
            fclose(pf);
        }
    }
    closedir(d);

    if (found[0] != '\0') {
        snprintf(out_bus, max_len, "%s", found);
        return 0;
    }
    return -1;
}

static int load_uvcvideo_module(void) {
    if (access(DRIVER_DIR, F_OK) == 0) return 0;

    pid_t pid = fork();
    if (pid < 0) return -1;
    if (pid == 0) {
        if (access("/run/current-system/sw/bin/modprobe", X_OK) == 0) {
            execl("/run/current-system/sw/bin/modprobe", "modprobe", "uvcvideo", NULL);
        }
        execlp("modprobe", "modprobe", "uvcvideo", NULL);
        _exit(127);
    }

    int status = 0;
    waitpid(pid, &status, 0);
    usleep(150000); /* wait 150ms for driver registration in sysfs */
    return (WIFEXITED(status) && WEXITSTATUS(status) == 0) ? 0 : -1;
}

/* returns 1 if active, 0 if disabled */
static int check_hw_status(const char *bus_id) {
    DIR *d = opendir(DRIVER_DIR);
    if (!d) return 0;

    struct dirent *entry;
    int is_active = 0;
    size_t bus_len = strlen(bus_id);

    while ((entry = readdir(d)) != NULL) {
        if (strncmp(entry->d_name, bus_id, bus_len) == 0) {
            if (entry->d_name[bus_len] == ':' || entry->d_name[bus_len] == '\0') {
                is_active = 1;
                break;
            }
        }
    }
    closedir(d);
    return is_active;
}

static int unbind_interfaces(const char *bus_id) {
    DIR *d = opendir(DRIVER_DIR);
    if (!d) return 0; /* driver already unloaded or not present */

    int unbind_fd = open(DRIVER_DIR "/unbind", O_WRONLY);
    if (unbind_fd < 0) {
        closedir(d);
        return -1;
    }

    struct dirent *entry;
    size_t bus_len = strlen(bus_id);

    while ((entry = readdir(d)) != NULL) {
        if (strncmp(entry->d_name, bus_id, bus_len) == 0) {
            if (entry->d_name[bus_len] == ':' || entry->d_name[bus_len] == '\0') {
                ssize_t len = (ssize_t)strlen(entry->d_name);
                (void)write(unbind_fd, entry->d_name, (size_t)len);
            }
        }
    }

    close(unbind_fd);
    closedir(d);
    return 0;
}

static int bind_interfaces(const char *bus_id) {
    if (load_uvcvideo_module() != 0) {
        fprintf(stderr, "vcam-hw: failed to load uvcvideo driver\n");
        return -1;
    }

    int bind_fd = open(DRIVER_DIR "/bind", O_WRONLY);
    if (bind_fd < 0) {
        perror("vcam-hw: open driver bind endpoint");
        return -1;
    }

    char dev_path[PATH_MAX];
    snprintf(dev_path, sizeof(dev_path), "%s/%s", USB_DEV_DIR, bus_id);

    DIR *d = opendir(dev_path);
    if (!d) {
        /* try direct bind if interface id was passed directly */
        ssize_t len = (ssize_t)strlen(bus_id);
        (void)write(bind_fd, bus_id, (size_t)len);
        close(bind_fd);
        return 0;
    }

    struct dirent *entry;
    size_t bus_len = strlen(bus_id);

    while ((entry = readdir(d)) != NULL) {
        if (strncmp(entry->d_name, bus_id, bus_len) == 0 && entry->d_name[bus_len] == ':') {
            /* verify if interface is already bound */
            char bound_link[PATH_MAX];
            snprintf(bound_link, sizeof(bound_link), "%s/%s", DRIVER_DIR, entry->d_name);
            if (access(bound_link, F_OK) == 0) {
                continue;
            }
            ssize_t len = (ssize_t)strlen(entry->d_name);
            (void)write(bind_fd, entry->d_name, (size_t)len);
        }
    }

    close(bind_fd);
    closedir(d);
    return 0;
}

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "usage: vcam-hw <toggle|enable|disable|status|modprobe> [bus_id]\n");
        return 1;
    }

    const char *action = argv[1];
    char bus_id[256] = {0};

    if (argc >= 3) {
        if (!is_valid_bus_id(argv[2])) {
            fprintf(stderr, "vcam-hw: invalid device bus id '%s'\n", argv[2]);
            return 1;
        }
        /* strip trailing :1.0 if user passed interface id instead of bus */
        snprintf(bus_id, sizeof(bus_id), "%s", argv[2]);
        char *colon = strchr(bus_id, ':');
        if (colon) *colon = '\0';
    } else {
        if (find_webcam_bus(bus_id, sizeof(bus_id)) != 0) {
            fprintf(stderr, "vcam-hw: unable to auto-detect webcam device bus\n");
            return 1;
        }
    }

    if (strcmp(action, "status") == 0) {
        int active = check_hw_status(bus_id);
        printf("%s (device: %s)\n", active ? "active" : "disabled", bus_id);
        return active ? 0 : 1;
    }

    if (strcmp(action, "enable") == 0 || strcmp(action, "bind") == 0) {
        return bind_interfaces(bus_id);
    }

    if (strcmp(action, "disable") == 0 || strcmp(action, "unbind") == 0) {
        return unbind_interfaces(bus_id);
    }

    if (strcmp(action, "toggle") == 0) {
        if (check_hw_status(bus_id)) {
            return unbind_interfaces(bus_id);
        } else {
            return bind_interfaces(bus_id);
        }
    }

    if (strcmp(action, "modprobe") == 0) {
        return load_uvcvideo_module();
    }

    fprintf(stderr, "vcam-hw: unknown action '%s'\n", action);
    return 1;
}
