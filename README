# MetaBinGv4 Toolkit

MetaBinGv4 provides a metagenomic classification for short-read and long-read sequencing data.  

---


## Installation

Compile all required binaries:

```bash
make

This will build the executables and place them in the `bin/` directory:

* `taxonomy_downloader`
* `genPathFiles`
* `DB_compress`
* `DB_unique`

---

## Step 1. Build the Database
### 1.1 Download genomes and taxonomy

```bash
./bin/download_genomes.sh -d DBNAME -l TYPE
```

* `DBNAME`: output directory name
* `TYPE`: library to download (ex. `archaea`, `bacteria`, `fungi`)

This downloads all RefSeq reference genomes with assembly levels:
`contig`, `scaffold`, `chromosome`, `complete`
and prepares taxonomy files.

**Usage example:**

```bash
./bin/download_genomes.sh -d test_db -l bacteria
```

This will create a directory `test_db/` containing downloaded genomes and taxonomy.

---

### 1.2 Construct the database

```bash
./bin/build_db.sh --db DBNAME --library TYPE [--srs|--lrs] [--kmer-size N] [--output FILE]
```

### Options:

* `--db, -d DBNAME` : database name (must match the download step).
* `--library, -l TYPE` : same library type as in download step (`archaea`, `bacteria`, `fungi`, `protozoa`).
* `--srs` : build a **short-read (SRS)** database.
* `--lrs` : build a **long-read (LRS)** database.
* `--kmer-size, -k N` : (SRS only) specify k-mer size (default: `6`).
* `--output, -o FILE` : output prefix for the database.

### Short-read mode (SRS)

```bash
./bin/build_db.sh -d test_db -l bacteria --srs
```

This will create a short-read database using **k = 6** (default) in 'test_db/'.

### Long-read mode (LRS)

```bash
./bin/build_db.sh -d test_db -l bacteria --lrs
```

This will create a long-read database in `test_db/`.

# Step 2. Classification

After building the database, you can classify your sequencing reads using the unified wrapper `classify.sh`.

### Long-read mode (LRS)

```bash
./bin/classify.sh --lrs -d DBNAME -i INPUT -o OUTPUT [--fasta|--fastq] [-t THREADS]
````

**Arguments:**

* `-d DBNAME` : database directory (must contain `lrs_db_Size`, `lrs_db_Suffix`, `lrs_db_Taxo`, and `build/nameFamily.txt`).
* `-i INPUT`  : input reads (FASTA/FASTQ).
* `-o OUTPUT` : output prefix.
* `--fasta|--fastq` : specify input format (default: `--fasta`).
* `-t THREADS` : number of threads (default: 1).


### Short-read mode (SRS, MetaBinGv4)

```bash
./bin/classify.sh --srs -d DBNAME -i INPUT -o OUTPUT [-t THREADS]
```

**Arguments:**

* `-i INPUT`  : input short-read FASTQ file.
* `-o OUTPUT` : output prefix.
* `-t THREADS` : number of threads (default: 1).
* `-d DBNAME` : (optional) database directory, default is `srs_db` under current folder.




## 5. Usage summary

1. Compile:

   ```bash
   make
   ```
2. Download genomes:

   ```bash
   ./bin/download_genomes.sh -d DBNAME -l bacteria
   ```
3. Build DB:

   ```bash
   ./bin/build_db.sh -d DBNAME -l bacteria --srs -k 6
   ```

   or

   ```bash
   ./bin/build_db.sh -d DBNAME -l bacteria --lrs
   ```
4. Classify:

    ```bash
    ./bin/classify.sh --lrs -d test_db -i example/input.fasta -o out --fasta -t 8
    ```
    
    or
    
    ```bash
    ./bin/classify.sh --srs -d test_db -i example/input.fastq -o out_srs -t 16
    ```


