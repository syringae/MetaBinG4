#!/bin/bash
#
# Unified wrapper for LRS (CDKAM) and SRS (MetaBinG4)
#

FSCRPT=$(readlink -f "$0")
LDIR=$(dirname "$FSCRPT")

show_help() {
    echo "Usage:"
    echo "  $0 --lrs  -d DBname -i input -o output [-t threads] [--fasta|--fastq]"
    echo "  $0 --srs  -i input -o output [-t threads]"
    echo
    echo "Options:"
    echo "  -i, --input       Input sequence file"
    echo "  -o, --output      Output base name"
    echo "  -d, --database    Database directory (LRS only)"
    echo "  -t, --threads     Number of threads (default: 1)"
    echo "  --fasta/--fastq   Input format (LRS only, default: fasta)"
    echo "  -h, --help        Show this help"
}

# Parse common args
MODE=$1
shift

if [ "$MODE" != "--lrs" ] && [ "$MODE" != "--srs" ]; then
    echo "[ERROR] Unknown mode: $MODE"
    show_help
    exit 1
fi

INPUT=""
OUTPUT=""
DBNAME=""
THREADS=1
FORMAT="--fasta"

# Parse options
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--input)
            INPUT=$2
            shift 2
            ;;
        -o|--output)
            OUTPUT=$2
            shift 2
            ;;
        -d|--database)
            DBNAME=$2
            shift 2
            ;;
        -t|--threads)
            THREADS=$2
            shift 2
            ;;
        --fasta|--fastq)
            FORMAT=$1
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "[ERROR] Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

if [ -z "$INPUT" ] || [ -z "$OUTPUT" ]; then
    echo "[ERROR] Input and output are required"
    show_help
    exit 1
fi

if [ ! -e "$INPUT" ]; then
    echo "[ERROR] Input file '$INPUT' does not exist"
    exit 1
fi

# -------- LRS Mode --------
if [ "$MODE" == "--lrs" ]; then
    if [ -z "$DBNAME" ]; then
        echo "[ERROR] LRS mode requires -d DBname"
        show_help
        exit 1
    fi

    # Проверка файлов базы
    for suffix in "Size" "Suffix" "Taxo"; do
        if [ ! -e "$DBNAME/lrs_db_$suffix" ]; then
            echo "[ERROR] Database missing file: lrs_db_$suffix in $DBNAME"
            exit 1
        fi
    done

    NAME_FAMILY="$DBNAME/build/nameFamily.txt"
    if [ ! -e "$NAME_FAMILY" ]; then
        echo "[ERROR] nameFamily.txt not found in $DBNAME/build/"
        exit 1
    fi

    echo "[INFO] Running LRS (CDKAM) mode..."
    $LDIR/classify_LRS "$DBNAME" "$NAME_FAMILY" "$INPUT" "$OUTPUT" "$FORMAT" "nthread" "$THREADS"
    echo "[INFO] LRS pipeline finished."

# -------- SRS Mode --------
else
    DATABASE="$DBNAME/srs_db"
    if [ ! -e "$DATABASE" ]; then
        echo "[ERROR] SRS database not found at $DATABASE"
        exit 1
    fi

    CLASS_FILE="${OUTPUT}.classify"
    TAXON_OUT="${OUTPUT}.taxonomy.tsv"

    echo "[INFO] Running SRS (MetaBinG4) mode..."
    ./bin/classify_SRS_GPU "$INPUT" "$DATABASE" "$THREADS" "$CLASS_FILE"

    # Run taxonomy analysis
    if [ ! -e "./src/taxonomy_analysis.py" ]; then
        echo "[ERROR] taxonomy_analysis.py not found"
        exit 1
    fi
    
    # TODO check taxonomy_analysis
    # python3 ./src/taxonomy_analysis.py "$CLASS_FILE" "$TAXON_OUT" taxonomy/nodes.dmp taxonomy/names.dmp
    echo "[INFO] SRS pipeline finished. Classification: $CLASS_FILE, Taxonomy: $TAXON_OUT"
fi
