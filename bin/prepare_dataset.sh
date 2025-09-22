#!/bin/bash

set -euo pipefail

# Check conda environment
if conda env list | grep -q "metabingv4"; then
    echo "[INFO] Conda environment 'metabingv4' found."
else
    echo "[INFO] Conda environment not found. Setting up..."
    ./env/setup_conda.sh
fi

eval "$(conda shell.bash hook)"
conda activate metabingv4

check_dependency() {
    if ! command -v "$1" &> /dev/null; then
        echo "[ERROR] $1 is not available."
        echo "Please make sure the 'metabingv4' conda environment is activated."
        echo "You can set it up by running: ./setup_conda.sh"
        echo "Then activate it with: conda activate metabingv4"
        exit 1
    fi
}

# Required tools
MASKER="dustmasker"
check_dependency "$MASKER"

# Parse arguments
DBNAME=""
LIBRARY=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --db|-d)
            DBNAME=$2
            shift 2
            ;;
        --library|-l)
            LIBRARY=$2
            shift 2
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage: $0 --db DBNAME --library TYPE"
            exit 1
            ;;
    esac
done

if [[ -z "$DBNAME" || -z "$LIBRARY" ]]; then
    echo "Usage: $0 --db DBNAME --library TYPE"
    exit 1
fi

WORKDIR="$DBNAME/$LIBRARY"
BUILDDIR="$DBNAME/build"
LIBRARY_FILE="$WORKDIR/library.fna"

mkdir -p "$BUILDDIR"


# Step 1. Run Perl script
echo "[INFO] Generating $LIBRARY_FILE with taxid headers"

perl scripts/merge_with_taxid.pl \
    "$DBNAME/mapping.json" \
    "$DBNAME/$LIBRARY.txt" \
    "$LIBRARY_FILE"


# Step 2. Mask low-complexity regions
echo "[INFO] Masking low-complexity regions"
if [[ ! -e "$BUILDDIR/library.masked.done" ]]; then
    $MASKER -in "$LIBRARY_FILE" -outfmt fasta | \
      sed -e '/^>/!s/[a-z]/x/g' > "$BUILDDIR/library.tmp"
    mv "$BUILDDIR/library.tmp" "$LIBRARY_FILE"
    touch "$BUILDDIR/library.masked.done"
fi

# Step 3. Generate premap
echo "[INFO] Running scan_fasta_file.pl"
perl scripts/scan_fasta_file.pl "$LIBRARY_FILE" > "$BUILDDIR/premap.txt"


# Step 4. Generate final library
echo "[INFO] Running genPathFiles"

genPathFiles "$BUILDDIR/premap.txt" \
               "taxonomy/nodes.dmp" \
               "$LIBRARY_FILE" \
               "$DBNAME"

echo "[INFO] DONE. Library is ready at $LIBRARY_FILE"
