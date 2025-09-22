#!/bin/bash
# run_full_pipeline.sh - Master script to run the complete pipeline

set -e

# Default values
DBNAME=""
DL_LIBRARY=""
KMER_SIZE=6
OUTPUT="database"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --db | -d)
            DBNAME=$2
            shift 2
            ;;
        --library | -l)
            DL_LIBRARY=$2
            shift 2
            ;;
        --kmer-size | -k)
            KMER_SIZE=$2
            shift 2
            ;;
        --output | -o)
            OUTPUT=$2
            shift 2
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done

if [[ -z "$DBNAME" || -z "$DL_LIBRARY" ]]; then
    echo "Usage: $0 --db DBNAME --library TYPE [--kmer-size N] [--output FILE]"
    echo "Supported TYPE: archaea, bacteria, fungi, protozoa"
    exit 1
fi

# Check if conda environment exists
#if conda env list | grep -q "ncbi-downloader"; then
#    echo "Conda environment 'ncbi-downloader' found."
#else
#    echo "Conda environment not found. Setting up..."
#    ./setup_conda.sh
#fi

# Activate the conda environment
#eval "$(conda shell.bash hook)"
#conda activate ncbi-downloader

# Step 1: Download the data
#echo "[PIPELINE] Step 1: Downloading genomes"
#./download_genomes.sh --db "$DBNAME" --download-library "$DL_LIBRARY"

# Step 2: Build the database
echo "[PIPELINE] Step 2: Building database"
MAPPING_FILE="$DBNAME/mapping.json"
FASTA_DIR="$DBNAME/$DL_LIBRARY/ncbi_dataset/data"

./src/build_sr_db.py \
    --taxid-map "$MAPPING_FILE" \
    --fasta-dir "$FASTA_DIR" \
    --output "$OUTPUT" \
    --kmer-size "$KMER_SIZE"

echo "[PIPELINE] Complete! Database built at $OUTPUT"