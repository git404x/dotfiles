#include "hw.h"

/* detect primary physical video capture device in sysfs */
int hw_detect_camera(char *out_dev, size_t max_len, const char *loopback_dev) {
    DIR *d = opendir("/sys/class/video4linux");
    if (!d) return -1;

    struct dirent *dir;
    int best_nr = 999;
    char found[264] = {0};

    while ((dir = readdir(d)) != NULL) {
        if (strncmp(dir->d_name, "video", 5) != 0) continue;
        int nr = atoi(dir->d_name + 5);

        char dev_path[264];
        snprintf(dev_path, sizeof(dev_path), "/dev/%s", dir->d_name);
        if (strcmp(dev_path, loopback_dev) == 0) continue;

        /* loopback devices lack a physical device symlink */
        char sys_dev[512];
        snprintf(sys_dev, sizeof(sys_dev), "/sys/class/video4linux/%s/device", dir->d_name);
        if (access(sys_dev, F_OK) != 0) continue;

        /* strictly check index=0 (primary video stream, skips metadata node) */
        char idx_path[512];
        snprintf(idx_path, sizeof(idx_path), "/sys/class/video4linux/%s/index", dir->d_name);
        FILE *f = fopen(idx_path, "r");
        if (f) {
            char idx_str[16] = {0};
            if (fgets(idx_str, sizeof(idx_str), f)) {
                int idx = atoi(idx_str);
                if (idx == 0 && nr < best_nr) {
                    best_nr = nr;
                    snprintf(found, sizeof(found), "%s", dev_path);
                }
            }
            fclose(f);
        }
    }
    closedir(d);

    if (found[0] != '\0') {
        strncpy(out_dev, found, max_len - 1);
        return 0;
    }
    return -1;
}
