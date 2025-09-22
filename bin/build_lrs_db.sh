#!/bin/bash
#
# MetaBinGv4: wrapper to build full database
#

set -euo pipefail

# -----------------------
# Parse arguments
# -----------------------
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
            echo "Usage: $0 --db DBNAME --library LIBRARY"
            exit 1
            ;;
    esac
done

if [[ -z "$DBNAME" || -z "$LIBRARY" ]]; then
    echo "Usage: $0 --db DBNAME --library LIBRARY"
    exit 1
fi

# -----------------------
# Step 1. prepare dataset
# -----------------------
echo "[STEP 1] Running prepare_dataset.sh"
./bin/prepare_dataset.sh -d "$DBNAME" -l "$LIBRARY"

# -----------------------
# Step 2. build pre-database
# -----------------------
echo "[STEP 2] Running buildDB"
./bin/DB_compress "$DBNAME/build/paths.txt" \
              "$DBNAME/build/nameFamily.txt" \
              "$DBNAME/build/$DBNAME"

# -----------------------
# Step 3. compress database
# -----------------------
echo "[STEP 3] Running DTB_unique"
./bin/DB_unique "${DBNAME}/build/${DBNAME}_prebuild" \
                "$DBNAME/$DBNAME"

echo "[DONE] Database built at $DBNAME/$DBNAME"
