#include <stdio.h>
#include <stdlib.h>
#include <syslog.h>

int main(int argc, char *argv[]) {
    // Open syslog with LOG_USER facility
    openlog("writer", LOG_PID, LOG_USER);

    // Check for exactly 2 arguments
    if (argc != 3) {
        syslog(LOG_ERR, "Invalid arguments. Usage: %s <file> <text>", argv[0]);
        closelog();
        return EXIT_FAILURE;
    }

    const char *file_path = argv[1];
    const char *text_to_write = argv[2];

    // Open the file (assume directory exists; do not create it)
    FILE *fp = fopen(file_path, "w");
    if (!fp) {
        syslog(LOG_ERR, "Failed to open file %s for writing", file_path);
        closelog();
        return EXIT_FAILURE;
    }

    // Write text to the file
    if (fprintf(fp, "%s", text_to_write) < 0) {
        syslog(LOG_ERR, "Failed to write to file %s", file_path);
        fclose(fp);
        closelog();
        return EXIT_FAILURE;
    }

    // Close the file
    fclose(fp);

    // Log success at LOG_DEBUG
    syslog(LOG_DEBUG, "Writing %s to %s", text_to_write, file_path);

    closelog();
    return EXIT_SUCCESS;
}

