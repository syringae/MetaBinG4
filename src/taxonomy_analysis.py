#!/usr/bin/env python3
"""
Taxonomy Analysis Script
Processes taxonomic classification data and generates a report with full lineage and relative abundance.

Usage: ./taxonomy_analysis.py [classify_output] [output_results.tsv] [nodes.dmp] [names.dmp]
"""

import argparse
import sys
from collections import defaultdict

def load_ncbi_taxonomy(nodes_file, names_file):
    """Load NCBI taxonomy data from nodes.dmp and names.dmp"""
    taxonomy = {}
    parent_map = {}
    
    print(f"Loading nodes from {nodes_file}...")
    with open(nodes_file, 'r') as f:
        for line_num, line in enumerate(f, 1):
            parts = line.strip().split('|')
            if len(parts) < 3:
                continue
                
            taxid = parts[0].strip()
            parent_taxid = parts[1].strip()
            rank = parts[2].strip()
            
            parent_map[taxid] = parent_taxid
            taxonomy[taxid] = {
                'name': '',
                'rank': rank,
                'parent': parent_taxid
            }
            
            #if line_num % 100000 == 0:
            #    print(f"Processed {line_num} nodes")
    
    print(f"Loading names from {names_file}...")
    with open(names_file, 'r') as f:
        for line_num, line in enumerate(f, 1):
            parts = line.strip().split('|')
            if len(parts) < 4:
                continue
                
            taxid = parts[0].strip()
            name = parts[1].strip()
            name_type = parts[3].strip()
            
            if name_type == 'scientific name' and taxid in taxonomy:
                taxonomy[taxid]['name'] = name
                
            #if line_num % 100000 == 0:
            #    print(f"Processed {line_num} names")
    
    print("Taxonomy loading complete!")
    return taxonomy, parent_map

def get_full_lineage(taxid, taxonomy, parent_map):
    """Get the full taxonomic lineage for a taxid"""
    lineage = {}
    current_id = taxid
    
    rank_order = ['kingdom', 'phylum', 'class', 'order', 'family', 'genus', 'species']
    for rank in rank_order:
        lineage[rank] = ''
    
    if current_id in taxonomy:
        current_rank = taxonomy[current_id]['rank']
        if current_rank in rank_order:
            lineage[current_rank] = taxonomy[current_id]['name']

    while current_id in parent_map and current_id != '1':
        parent_id = parent_map[current_id]
        if parent_id in taxonomy:
            parent_rank = taxonomy[parent_id]['rank']
            parent_name = taxonomy[parent_id]['name']
            
            if parent_rank in rank_order and not lineage[parent_rank]:
                lineage[parent_rank] = parent_name
        
        current_id = parent_id
    
    return lineage

def process_taxonomy_file(input_file):
    """Process the taxonomy classification file"""
    counts = defaultdict(int)
    total_reads = 0
    unclassified = 0
    
    print(f"Processing {input_file}...")
    with open(input_file, 'r') as f:
        for line_num, line in enumerate(f, 1):
            if line.startswith('>'):
                parts = line.strip().split()
                if not parts:
                    continue
                    
                taxid = parts[-1]
                
                if taxid.isdigit():
                    counts[taxid] += 1
                    total_reads += 1
                else:
                    unclassified += 1
                    
            if line_num % 100000 == 0:
                print(f"Processed {line_num} lines")
    
    print(f"Total classified reads: {total_reads}")
    print(f"Unclassified reads: {unclassified}")
    
    return counts, total_reads, unclassified

def main():
    parser = argparse.ArgumentParser(description='Process taxonomy data with full lineage and relative abundance')
    parser.add_argument('input', help='Input classification file')
    parser.add_argument('output', help='Output file')
    parser.add_argument('nodes', help='NCBI nodes.dmp file')
    parser.add_argument('names', help='NCBI names.dmp file')
    
    args = parser.parse_args()
    
    taxonomy, parent_map = load_ncbi_taxonomy(args.nodes, args.names)
    counts, total_reads, unclassified = process_taxonomy_file(args.input)
    
    results = []
    unknown_taxids = []
    
    for taxid, count in counts.items():
        if taxid in taxonomy:
            lineage = get_full_lineage(taxid, taxonomy, parent_map)
            relative_abundance = (count / total_reads) * 100 if total_reads > 0 else 0
            result_entry = {
                'taxid': taxid,
                'count': count,
                'relative_abundance': relative_abundance
            }
            result_entry.update(lineage)
            
            results.append(result_entry)
        else:
            unknown_taxids.append(taxid)
    
    if unknown_taxids:
        print(f"Found {len(unknown_taxids)} unknown tax IDs")
    
    rank_order = ['kingdom', 'phylum', 'class', 'order', 'family', 'genus', 'species']
    column_order = ['taxid'] + rank_order + ['count', 'relative_abundance']
    
    with open(args.output, 'w') as f:
        f.write('\t'.join(column_order) + '\n')
        for result in results:
            row = []
            for col in column_order:
                if col in result:
                    if col == 'relative_abundance':
                        row.append(f"{result[col]:.6f}")
                    else:
                        row.append(str(result[col]))
                else:
                    row.append('')
            f.write('\t'.join(row) + '\n')
    
    print(f"\nSummary:")
    print(f"Total classified reads: {total_reads}")
    print(f"Unclassified reads: {unclassified}")
    print(f"Total tax IDs found: {len(counts)}")
    print(f"Tax IDs with taxonomy info: {len(results)}")
    print(f"Unknown tax IDs: {len(unknown_taxids)}")
    print(f"Results saved to {args.output}")

if __name__ == '__main__':
    main()