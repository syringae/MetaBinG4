#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <getopt.h>

#define MAX_PATH_LENGTH 1024
#define TAXONOMY_SCRIPT "/src/taxonomy_analysis.py"

// Function declarations
void show_help();
int check_taxonomy_files(const char *taxonomy_dir);
int run_metabing(const char *input_file, const char *database, const char *output_file, int threads);
int run_taxonomy_analysis(const char *classification_file, const char *output_file, const char *taxonomy_dir);
int file_exists(const char *path);

// Global variables for command line options
struct global_args_t {
    char *input_file;
    char *output_base;
    char *database;
    int threads;
    char *taxonomy_dir;
    int skip_download;
    int skip_classification;
} global_args;

int main(int argc, char *argv[]) {
    // Initialize defaults
    global_args.threads = 1;
    global_args.taxonomy_dir = (char *)"taxonomy";
    global_args.skip_download = 0;
    global_args.skip_classification = 0;
    
    int opt;
    int required_params = 0;
    
    // Define long options
    struct option long_options[] = {
        {"input", required_argument, NULL, 'i'},
        {"database", required_argument, NULL, 'd'},
        {"threads", required_argument, NULL, 't'},
        {"output", required_argument, NULL, 'o'},
        {"taxonomy-dir", required_argument, NULL, 'T'},
        {"skip-download", no_argument, NULL, 'S'},
        {"skip-classification", no_argument, NULL, 'C'},
        {"help", no_argument, NULL, 'h'},
        {NULL, 0, NULL, 0}
    };
    
    // Parse command line arguments
    while ((opt = getopt_long(argc, argv, "i:d:t:o:T:SCh", long_options, NULL)) != -1) {
        switch (opt) {
            case 'i':
                global_args.input_file = optarg;
                required_params++;
                break;
            case 'o':
                global_args.output_base = optarg;
                required_params++;
                break;
            case 'd':
                global_args.database = optarg;
                required_params++;
                break;
            case 't':
                global_args.threads = atoi(optarg);
                required_params++;
                break;
            case 'T':
                global_args.taxonomy_dir = optarg;
                break;
            case 'S':
                global_args.skip_download = 1;
                break;
            case 'C':
                global_args.skip_classification = 1;
                break;
            case 'h':
                show_help();
                return 0;
            default:
                show_help();
                return 1;
        }
    }
    
    // Check required parameters
    if (required_params < 4) {
        fprintf(stderr, "[ERROR] Missing required parameters\n");
        show_help();
        return 1;
    }
    
    // Check input file
    if (!file_exists(global_args.input_file)) {
        fprintf(stderr, "[ERROR] Input file '%s' does not exist\n", global_args.input_file);
        return 1;
    }
    
    // Check database dir
    if (!file_exists(global_args.database)) {
        fprintf(stderr, "[ERROR] Database directory '%s' does not exist\n", global_args.database);
        return 1;
    }
    
    // Check/download taxonomy files
    if (!global_args.skip_download) {
        if (!check_taxonomy_files(global_args.taxonomy_dir)) {
            fprintf(stderr, "[ERROR] Failed to obtain taxonomy files\n");
            return 1;
        }
    }
    
    // Run classification
    char classification_file[MAX_PATH_LENGTH];
    snprintf(classification_file, sizeof(classification_file), "%s.classify", global_args.output_base);
    
    if (!global_args.skip_classification) {
        if (!run_metabing(global_args.input_file, global_args.database, classification_file, global_args.threads)) {
            fprintf(stderr, "[ERROR] Classification failed\n");
            return 1;
        }
    } else {
        printf("[INFO] Skipping classification step\n");
        if (!file_exists(classification_file)) {
            fprintf(stderr, "[ERROR] Classification file '%s' does not exist\n", classification_file);
            return 1;
        }
    }
    
    // Run taxonomy analysis
    char taxonomy_output[MAX_PATH_LENGTH];
    snprintf(taxonomy_output, sizeof(taxonomy_output), "%s.taxonomy.tsv", global_args.output_base);
    
    if (!run_taxonomy_analysis(classification_file, taxonomy_output, global_args.taxonomy_dir)) {
        fprintf(stderr, "[ERROR] Taxonomy analysis failed\n");
        return 1;
    }
    
    printf("\n[INFO] Pipeline completed successfully!\n");
    printf("[INFO] Classification results: %s\n", classification_file);
    printf("[INFO] Taxonomy analysis: %s\n", taxonomy_output);
    
    return 0;
}

void show_help() {
    printf("MetaBinG4 - Taxonomic classification with statistical analysis\n");
    printf("Usage: runMetaBinG4 -i <input fasta> -o <output> -d <database> -t <threads> [options]\n\n");
    printf("Required parameters:\n");
    printf("  -i, --input <file>          Input sequence file in FASTA format\n");
    printf("  -d, --database <dir>        Database directory for MetaBinG4\n");      
    printf("  -t, --threads <n>           Number of threads (default: 1)\n");
    printf("  -o, --output <base>         Output base name for results\n");
    printf("Optional parameters:\n");
    printf("  -T, --taxonomy-dir <dir>    Directory for NCBI taxonomy files (default: taxonomy)\n");
    printf("  -S, --skip-download         Skip downloading taxonomy files\n");
    printf("  -C, --skip-classification   Skip the classification step\n");
    printf("  -h, --help                  Show this help message\n");
}

int check_taxonomy_files(const char *taxonomy_dir) {
    printf("[INFO] Checking taxonomy files with taxonomy_downloader...\n");

    char command[MAX_PATH_LENGTH * 2];
    snprintf(command, sizeof(command), "./bin/taxonomy_downloader \"%s\"", taxonomy_dir);

    int result = system(command);
    if (result != 0) {
        fprintf(stderr, "[ERROR] taxonomy_downloader failed\n");
        return 0;
    }

    char nodes_file[MAX_PATH_LENGTH];
    char names_file[MAX_PATH_LENGTH];
    snprintf(nodes_file, sizeof(nodes_file), "%s/nodes.dmp", taxonomy_dir);
    snprintf(names_file, sizeof(names_file), "%s/names.dmp", taxonomy_dir);

    if (!file_exists(nodes_file) || !file_exists(names_file)) {
        fprintf(stderr, "[ERROR] Taxonomy files missing after taxonomy_downloader run\n");
        return 0;
    }

    printf("[INFO] Taxonomy files are ready!\n");
    return 1;
}

int run_metabing(const char *input_file, const char *database, const char *output_file, int threads) {
    printf("[INFO] Running MetaBinG4 classification on %s...\n", input_file);
    
    char command[MAX_PATH_LENGTH * 4];
    snprintf(command, sizeof(command), 
             "./bin/MetaBinGv4_srs \"%s\" \"%s\" %d \"%s\"", 
             input_file, database, threads, output_file);
    
    int result = system(command);
    
    if (result == 0) {
        printf("[INFO] MetaBinG4 classification completed successfully!\n");
        return 1;
    } else {
        fprintf(stderr, "[ERROR] Error running MetaBinG4\n");
        return 0;
    }
}

int run_taxonomy_analysis(const char *classification_file, const char *output_file, const char *taxonomy_dir) {
    printf("[INFO] Running taxonomy analysis...\n");
    
    char nodes_file[MAX_PATH_LENGTH];
    char names_file[MAX_PATH_LENGTH];
    
    snprintf(nodes_file, sizeof(nodes_file), "%s/nodes.dmp", taxonomy_dir);
    snprintf(names_file, sizeof(names_file), "%s/names.dmp", taxonomy_dir);
    
    if (!file_exists(TAXONOMY_SCRIPT)) {
        fprintf(stderr, "[ERROR] Taxonomy analysis script '%s' not found\n", TAXONOMY_SCRIPT);
        return 0;
    }
    
    char command[MAX_PATH_LENGTH * 6];
    snprintf(command, sizeof(command), 
             "python3 \"%s\" \"%s\" \"%s\" \"%s\" \"%s\"", 
             TAXONOMY_SCRIPT, classification_file, output_file, nodes_file, names_file);
    
    int result = system(command);
    
    if (result == 0) {
        printf("[INFO] Taxonomy analysis completed successfully!\n");
        return 1;
    } else {
        fprintf(stderr, "[ERROR] Error running taxonomy analysis\n");
        return 0;
    }
}

int file_exists(const char *path) {
    struct stat buffer;
    return (stat(path, &buffer) == 0);
}
