#!/bin/bash
#
# CDKAM: a metagenomic classification tool using discriminative k-mers and approximate matching strategy
# Copyright 2019-2020
# Department of Bioinformatics and Biostatistics, Shanghai Jiao Tong University
# Contact information: buikien.dp@sjtu.edu.cn, ccwei@sjtu.edu.cn
#

DBDR=$1
RANK=0
FSCRPT=$(readlink -f "$0")
LDIR=$(dirname "$FSCRPT")

if [ $# -lt 4 ]; then
	echo "Usage: $0 DBname input output --fasta/--fastq"
	echo "Or"
	echo "Usage: $0 DBname input output --fasta/--fastq nthread N"
	exit
fi

for suffix in "Size" "Suffix" "Taxo"
do
    if [ ! -e "$LDIR/$DBDIR/lrs_db_$suffix" ]; then
        echo "Database missing file: lrs_db_$suffix in $DBDIR"
        exit 1
    fi
done

$LDIR/classify_LRS $LDIR/$DBDIR/lrs_db $LDIR/$DBDR/build/nameFamily.txt $2 $3 $4 $5 $6
