#!/usr/bin/env perl

# Reads a manifest-like mapping file (assembly accession -> taxid), which
# indicates taxonomic identifiers for already downloaded genome FASTA files.
# Processes all provided files, decompresses them if needed, and merges them
# into a single library.fna file. During merging, each sequence header is
# modified to include the corresponding taxid in the format:
# >CDKAM|<taxid>|<original_header>
#
# Unlike the original downloader script, this version does not fetch files
# via FTP/rsync. It assumes the genome FASTA files are already present in a
# specified directory.
#
# Used for CDKAM: a metagenomic classification tool using discriminative
# k-mers and approximate matching strategy.

use strict;
use warnings;
use File::Basename;
use JSON;
use List::Util qw/max/;

my $PROG = basename $0;

# ======================
# Parse command-line args
# ======================
if (@ARGV != 3) {
    die "Usage: $PROG mapping.json file_list.txt output.fna\n";
}

my ($mapping_file, $file_list, $output_file) = @ARGV;
# читаем mapping.json
open my $mapfh, "<", $mapping_file or die "$PROG: can't open $mapping_file: $!\n";
my $json_text = do { local $/; <$mapfh> };
close $mapfh;

my $map_data = decode_json($json_text);
my %mapping  = map { $_->{accession} => $_->{taxId} } @$map_data;

# читаем список файлов
open my $listfh, "<", $file_list or die "$PROG: can't open $file_list: $!\n";
my @fasta_files = map { chomp; $_ } <$listfh>;
close $listfh;

# открываем итоговый файл
open my $outfh, ">", $output_file or die "$PROG: can't write $output_file: $!\n";

print STDERR "Step 1/2: Processing local FASTA files...\n";

my $projects_added   = 0;
my $sequences_added  = 0;
my $bases_added      = 0;
my $ch               = "bp";
my $max_out_chars    = 0;

foreach my $fasta (@fasta_files) {
    # ищем accession (GCF_xxx)
    my ($acc) = $fasta =~ /(GCF_\d+\.\d+)/;
    unless ($acc) {
        warn "$PROG: no accession found in path $fasta, skipping\n";
        next;
    }

    my $taxid = $mapping{$acc};
    unless ($taxid) {
        warn "$PROG: no taxid mapping for accession $acc, skipping\n";
        next;
    }

    open my $infh, "<", $fasta or die "$PROG: can't open $fasta: $!\n";
    while (<$infh>) {
        if (/^>/) {
            s/^>/>CDKAM|$acc|$taxid|/;
            $sequences_added++;
        } else {
            $bases_added += length($_) - 1;
        }
        print $outfh $_;
    }
    close $infh;

    $projects_added++;
    my $out_line = progress_line($projects_added, scalar @fasta_files,
                                 $sequences_added, $bases_added) . "...";
    $max_out_chars = max(length($out_line), $max_out_chars);
    my $space_line = " " x $max_out_chars;
    print STDERR "\r$space_line\r$out_line" if -t STDERR;
}

close $outfh;
print STDERR " done.\n" if -t STDERR;

print STDERR "Step 2/2: Library complete: $output_file\n";

# функция прогресса
sub progress_line {
    my ($projs, $total_projs, $seqs, $chs) = @_;
    my $line = "Processed ";
    $line .= ($projs == $total_projs) ? "$projs" : "$projs/$total_projs";
    $line .= " project" . ($total_projs > 1 ? 's' : '') . " ";
    $line .= "($seqs sequence" . ($seqs > 1 ? 's' : '') . ", ";
    my $prefix;
    my @prefixes = qw/k M G T P E/;
    while (@prefixes && $chs >= 1000) {
        $prefix = shift @prefixes;
        $chs /= 1000;
    }
    if (defined $prefix) {
        $line .= sprintf '%.2f %s%s)', $chs, $prefix, $ch;
    } else {
        $line .= "$chs $ch)";
    }
    return $line;
}
