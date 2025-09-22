#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TAXONOMY_BIN="$ROOT_DIR/bin/taxonomy_downloader"
TAXONOMY_DIR="$ROOT_DIR/taxonomy"

check_dependency() {
    if ! command -v "$1" &> /dev/null; then
        echo "[ERROR] $1 is not available."
        echo "Please make sure the 'metabingv4' conda environment is activated."
        echo "Run: conda activate metabingv4"
        exit 1
    fi
}

# Check conda env
if conda env list | grep -q "metabingv4"; then
    echo "[INFO] Conda environment 'metabingv4' found."
else
    echo "[INFO] Conda environment not found. Setting up..."
    "$ROOT_DIR/env/setup_conda.sh"
fi

eval "$(conda shell.bash hook)"
conda activate metabingv4

check_dependency "datasets"
check_dependency "jq"
check_dependency "unzip"

# Parse arguments
DBNAME=""
DL_LIBRARY=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --db|-d)
            DBNAME=$2
            shift 2
            ;;
        --download-library|-l)
            DL_LIBRARY=$2
            shift 2
            ;;
        --taxonomy-dir|-T)
            TAXONOMY_DIR=$2
            shift 2
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done

if [[ -z "$DBNAME" || -z "$DL_LIBRARY" ]]; then
    echo "Usage: $0 --db DBNAME --download-library TYPE [--taxonomy-dir DIR]"
    echo "Short: -d DBNAME -l TYPE -T DIR"
    echo "Supported TYPE: archaea, bacteria, fungi, protozoa"
    exit 1
fi


# Step 1: Taxonomy
echo "[INFO] Checking NCBI taxonomy files..."
if [[ ! -x "$TAXONOMY_BIN" ]]; then
    echo "[ERROR] taxonomy_downloader binary not found at $TAXONOMY_BIN"
    echo "Please compile with: make"
    exit 1
fi

"$TAXONOMY_BIN" "$TAXONOMY_DIR"

# Step 2: Download genomes
mkdir -p "$DBNAME/$DL_LIBRARY"

echo "[INFO] Downloading $DL_LIBRARY genomes into $DBNAME/$DL_LIBRARY"

datasets download genome taxon "$DL_LIBRARY" \
    --assembly-level contig,scaffold,chromosome,complete \
    --reference --include genome \
    --filename "$DBNAME/$DL_LIBRARY.zip"

unzip -o "$DBNAME/$DL_LIBRARY.zip" -d "$DBNAME/$DL_LIBRARY"

find "$DBNAME/$DL_LIBRARY" -name "*.fna" > "$DBNAME/$DL_LIBRARY.txt"
echo "[INFO] Wrote file list to $DBNAME/$DL_LIBRARY.txt"

# Step 3: Mapping file
echo "[INFO] Creating mapping between assembly accession and taxid"

JSONL_PATH=$(find "$DBNAME/$DL_LIBRARY" -name "assembly_data_report.jsonl" | head -1)

if [[ -z "$JSONL_PATH" ]]; then
    echo "[ERROR] assembly_data_report.jsonl not found"
    exit 1
fi

jq -r '[.accession, .organism.taxId] | @tsv' "$JSONL_PATH" | \
    while IFS=$'\t' read -r accession taxid; do
        printf '{"accession": "%s", "taxId": %s}\n' "$accession" "$taxid"
    done | jq -s . > "$DBNAME/mapping.json"

echo "[INFO] Mapping file created at $DBNAME/mapping.json"
echo "[DONE] Genomes downloaded and taxonomy prepared."
