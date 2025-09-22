#!/usr/bin/env python3

import argparse
import json
import os
import glob
import math
import time

def load_mapping(mapping_file):
    """Load assembly accession to taxid mapping"""
    mapping = {}
    with open(mapping_file, 'r') as fh:
        data = json.load(fh)        
        for entry in data:
            acc = (entry.get('accession') or entry.get('Assembly Accession') or
                entry.get('assembly_accession'))
            tax = (entry.get('taxId') or entry.get('Taxonomy id') or 
                entry.get('Taxonomy ID') or entry.get('taxid'))        
            if acc is None or tax is None:
                continue  
            mapping[acc] = int(tax)    
    return mapping
    

def find_fasta_file(fasta_dir, assembly_accession):
    """Find genomic FASTA file by accession"""
    fasta_dir_final = os.path.join(fasta_dir, assembly_accession)
    fasta_pattern = os.path.join(fasta_dir_final, '*_genomic.fna')
    fasta_files = glob.glob(fasta_pattern)
    return fasta_files[0] if fasta_files else None


def char2num(chars):
    """Convert nucleotide sequence to numeric (A=0, T=1, C=2, G=3)"""
    return ''.join({'A': '0', 'a': '0',
                    'T': '1', 't': '1',
                    'C': '2', 'c': '2',
                    'G': '3', 'g': '3'}.get(c, '') for c in chars)


def revcompl(seq):
    """Reverse complement of numeric DNA"""
    complement = {'0': '1', '1': '0', '2': '3', '3': '2'}
    return ''.join(complement[b] for b in reversed(seq))


def computep(seq, kfreq, kmer_num_m, n):
    """Compute k-mer frequencies"""
    for j in range(len(seq) - n + 1):
        c = seq[j:j+n]
        index = 0
        for p in range(len(c) - 1):
            index = index * 4 + int(c[p])
        kmer_num_m[index] += 1
        index = index * 4 + int(c[-1])
        kfreq[index] += 1
    return kfreq, kmer_num_m


def read_fasta_file(fasta_file):
    """Read all non-plasmid sequences from FASTA and concatenate them"""
    sequences_parts = []
    current_is_plasmid = False

    with open(fasta_file, 'r') as fasta:
        for line in fasta:
            line = line.strip()
            if line.startswith('>'):
                if 'plasmid' in line.lower():
                    current_is_plasmid = True
                else:
                    current_is_plasmid = False
            else:
                if not current_is_plasmid:
                    sequences_parts.append(line)

    sequence = ''.join(sequences_parts)
    return char2num(sequence)


def build_database(mapping_file, fasta_dir, output_file, kmer_size):
    assembly_to_taxid_map = load_mapping(mapping_file)
    col_num = 4 ** kmer_size
    output_vectors = []

    with open(output_file, 'w') as out:
        for assembly_accession, taxid in assembly_to_taxid_map.items():
            kfreq = [0] * col_num
            kmer_num_m = [0] * (col_num // 4)

            fasta_file = find_fasta_file(fasta_dir, assembly_accession)
            if not fasta_file:
                print(f"[WARNING] No FASTA file found for {assembly_accession}")
                continue

            sequence = read_fasta_file(fasta_file)
            if not sequence:
                print(f"[WARNING] Empty sequence for {assembly_accession}")
                continue

            kfreq, kmer_num_m = computep(sequence, kfreq, kmer_num_m, kmer_size)
            sequence = revcompl(sequence)
            kfreq, kmer_num_m = computep(sequence, kfreq, kmer_num_m, kmer_size)

            vector = [str(taxid)]
            for j in range(col_num):
                index = j // 4
                if kmer_num_m[index] > 0 and kfreq[j] > 0:
                    vector.append(f"{(-1) * math.log(kfreq[j] / kmer_num_m[index]):.4f}")
                else:
                    vector.append("10")
            output_vectors.append("\t".join(vector) + "\n")

            out.write("\t".join(vector) + "\n")


def main():
    parser = argparse.ArgumentParser(description="Build database for metagenomic classification")
    parser.add_argument("--taxid-map", "-m", required=True, help="JSON file mapping assembly accessions to taxonomy IDs")
    parser.add_argument("--fasta-dir", "-f", required=True, help="Directory containing FASTA files")
    parser.add_argument("--output", "-o", default="db_vectors.tsv", help="Output database file")
    parser.add_argument("--kmer-size", "-k", type=int, default=6, help="K-mer size (default: 6)")

    args = parser.parse_args()

    start_time = time.perf_counter()
    build_database(args.taxid_map, args.fasta_dir, args.output, args.kmer_size)
    end_time = time.perf_counter()

    print(f"[INFO] Database written to {args.output}")
    print(f"[INFO] Total execution time: {end_time - start_time:.2f} seconds")


if __name__ == "__main__":
    main()

