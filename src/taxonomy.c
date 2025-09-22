#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>
#include "taxonomy.h"


#define MAX_PATH_LENGTH 1024

int download_file(const char *url, const char *destination) {
    printf("[INFO] Downloading %s to %s...\n", url, destination);
    char command[MAX_PATH_LENGTH * 3];

    snprintf(command, sizeof(command), "wget -O \"%s\" \"%s\" > /dev/null 2>&1", destination, url);
    int result = system(command);

    if (result != 0) {
        snprintf(command, sizeof(command), "curl -o \"%s\" \"%s\" > /dev/null 2>&1", destination, url);
        result = system(command);
    }

    if (result == 0) {
        return 1;
    } else {
        fprintf(stderr, "[ERROR] Error downloading file\n");
        return 0;
    }
}

int extract_tar_gz(const char *file_path, const char *extract_to) {
    printf("Extracting %s to %s...\n", file_path, extract_to);
    char command[MAX_PATH_LENGTH * 3];
    snprintf(command, sizeof(command), "tar -xzf \"%s\" -C \"%s\" > /dev/null 2>&1", file_path, extract_to);

    int result = system(command);

    if (result == 0) {
        return 1;
    } else {
        fprintf(stderr, "[ERROR] Error extracting file\n");
        return 0;
    }
}

int download_ncbi_taxonomy(const char *taxonomy_dir) {
    char command[MAX_PATH_LENGTH];
    snprintf(command, sizeof(command), "mkdir -p \"%s\"", taxonomy_dir);
    if (system(command) != 0) {
        fprintf(stderr, "[ERROR] Failed to create directory %s\n", taxonomy_dir);
        return 0; 
    }

    char taxdump_path[MAX_PATH_LENGTH];
    snprintf(taxdump_path, sizeof(taxdump_path), "%s/taxdump.tar.gz", taxonomy_dir);

    if (!download_file(TAXDUMP_URL, taxdump_path)) {
        return 0;
    }

    if (!extract_tar_gz(taxdump_path, taxonomy_dir)) {
        return 0;
    }

    remove(taxdump_path);

    char nodes_file[MAX_PATH_LENGTH];
    char names_file[MAX_PATH_LENGTH];

    snprintf(nodes_file, sizeof(nodes_file), "%s/nodes.dmp", taxonomy_dir);
    snprintf(names_file, sizeof(names_file), "%s/names.dmp", taxonomy_dir);

    if (file_exists(nodes_file) && file_exists(names_file)) {
        printf("[INFO] NCBI taxonomy files are ready!\n");
        return 1;   
    } else {
        fprintf(stderr, "[ERROR] Required taxonomy files not found after download\n");
        return 0;   
    }
}

int check_taxonomy_files(const char *taxonomy_dir) {
    char nodes_file[MAX_PATH_LENGTH];
    char names_file[MAX_PATH_LENGTH];

    snprintf(nodes_file, sizeof(nodes_file), "%s/nodes.dmp", taxonomy_dir);
    snprintf(names_file, sizeof(names_file), "%s/names.dmp", taxonomy_dir);

    if (!file_exists(nodes_file) || !file_exists(names_file)) {
        printf("[INFO] Taxonomy files not found. Downloading...\n");
        return download_ncbi_taxonomy(taxonomy_dir);
    }

    if (is_file_older_than_days(nodes_file, 90) || is_file_older_than_days(names_file, 90)) {
        printf("[INFO] Taxonomy files are older than 90 days. Updating...\n");
        return download_ncbi_taxonomy(taxonomy_dir);
    }

    printf("[INFO] Taxonomy files are up to date.\n");
    return 1;
}

int file_exists(const char *path) {
    struct stat buffer;
    return (stat(path, &buffer) == 0);
}

int is_file_older_than_days(const char *path, int days) {
    struct stat file_stat;
    if (stat(path, &file_stat) != 0) {
        return 1;
    }

    time_t now = time(NULL);
    time_t file_time = file_stat.st_mtime;
    double seconds_diff = difftime(now, file_time);
    int days_diff = seconds_diff / (60 * 60 * 24);

    return days_diff > days;
}

int main(int argc, char *argv[]) {
    const char *taxonomy_dir = "taxonomy";

    if (argc > 1) {
        taxonomy_dir = argv[1];
    }

    printf("[INFO] Checking taxonomy files in: %s\n", taxonomy_dir);

    if (check_taxonomy_files(taxonomy_dir)) {
        return 0;
    } else {
        fprintf(stderr, "[ERROR] Failed to prepare taxonomy.\n");
        return 1;
    }
}
