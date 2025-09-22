#!/bin/bash
# build_db.sh – unified database builder (SR/LRS)

set -euo pipefail

DBNAME=""
LIBRARY=""
KMER_SIZE=6
OUTPUT=""
MODE=""

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
        --kmer-size|-k)
            KMER_SIZE=$2
            shift 2
            ;;
        --output|-o)
            OUTPUT=$2
            shift 2
            ;;
        --srs)
            MODE="SRS"
            shift 1
            ;;
        --lrs)
            MODE="LRS"
            shift 1
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage: $0 --db DBNAME --library LIBRARY [--srs|--lrs] [--kmer-size N] [--output FILE]"
            exit 1
            ;;
    esac
done

# Usage
if [[ -z "$DBNAME" || -z "$LIBRARY" || -z "$MODE" ]]; then
    echo "Usage: $0 --db DBNAME --library LIBRARY [--srs|--lrs] [--kmer-size N] [--output FILE]"
    exit 1
fi

# Setting output names
if [[ "$MODE" == "SRS" ]]; then
    if [[ -z "$OUTPUT" ]]; then
        OUTPUT="${DBNAME}/srs_db"
    fi
elif [[ "$MODE" == "LRS" ]]; then
    if [[ -z "$OUTPUT" ]]; then
        OUTPUT="${DBNAME}/lrs_db"
    fi
fi

# Run depending on MODE
if [[ "$MODE" == "SRS" ]]; then
    echo "[PIPELINE] Short-read mode selected"
    echo "[INFO] k-mer size = $KMER_SIZE"
    
    MAPPING_FILE="$DBNAME/mapping.json"
    FASTA_DIR="$DBNAME/$LIBRARY/ncbi_dataset/data"

    ./src/build_sr_db.py \
        --taxid-map "$MAPPING_FILE" \
        --fasta-dir "$FASTA_DIR" \
        --output "$OUTPUT" \
        --kmer-size "$KMER_SIZE"

    echo "[DONE] SRS database built at $OUTPUT"

elif [[ "$MODE" == "LRS" ]]; then
    echo "[PIPELINE] Long-read mode selected"

    echo "[STEP 1] Running prepare_dataset.sh"
    ./bin/prepare_dataset.sh -d "$DBNAME" -l "$LIBRARY"

    echo "[STEP 2] Running DB_compress"
    ./bin/DB_compress "$DBNAME/build/paths.txt" \
                      "$DBNAME/build/nameFamily.txt" \
                      "$OUTPUT"
                      
    echo "[STEP 3] Running DB_unique"
    ./bin/DB_unique "${OUTPUT}_prebuild" \
                    "$OUTPUT"

    echo "[DONE] LRS database built at $OUTPUT"
fi
