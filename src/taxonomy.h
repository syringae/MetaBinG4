#ifndef TAXONOMY_H
#define TAXONOMY_H

#define TAXDUMP_URL "https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz"

int download_file(const char *url, const char *destination);
int extract_tar_gz(const char *file_path, const char *extract_to);
int download_ncbi_taxonomy(const char *taxonomy_dir);
int check_taxonomy_files(const char *taxonomy_dir);
int file_exists(const char *path);
int is_file_older_than_days(const char *path, int days);

#endif
