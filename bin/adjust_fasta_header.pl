#!/usr/bin/perl

use strict;

&usage() unless scalar(@ARGV) == 3;

my $species = $ARGV[0];
my $inputfile = $ARGV[1];
my $idField = $ARGV[2];

open(IN, $inputfile) || die "Can't open input file '$inputfile'\n";
open(OUT, ">$species.fasta") || die "Can't open output file '$species.fasta'\n";

my %ids;
while(<IN>) {
  if (/\>/) {
    s/^\>\s*//;
    s/\s+/ /g;
    s/\s*\|\s*/\|/g;
    my @a = split(/[\s\|]/);
    my $id = $a[$idField-1];
    die "Fasta file '$inputfile' contains a duplicate id: $id\n" if $ids{$id};
    $ids{$id} = 1;
    print OUT ">$species|$id\n";
  } else {
    print OUT $_;
  }
}



sub usage {
print STDERR "
Modify sequence headers by inserting species.

Usage:
  adjust_fasta.pl species fasta_file id_field

where:
  species:     string representing species of fasta
  fasta_file:  the input fasta file
  id_field:    a number indicating what field in the definition line contains
               the protein ID.  Fields are separated by either ' ' or '|'. Any
               spaces immediately following the '>' are ignored.  The first
               field is 1. For example, in the following definition line, the
               ID (AP_000668.1) is in field 4:  >gi|89106888|ref|AP_000668.1|

Input file requirements:
  (1) .fasta format
  (2) a unique id is provided for each sequence, and is in the field specified
      by id_field

Output file format:
  (1) .fasta format
  (2) definition line is of the form:
         >species|unique_protein_id

The output file is named species.fasta

Note: if your input files do not meet the requirements, you can do some simple perl or awk processing of them to create the required input files to this program, or the required output files.  This program is provided as a convenience, but OrthoMCL users are expected to have the scripting skills to provide OrthoMCL compliant .fasta files.

EXAMPLE: adjust_fasta.pl Homo_sapiens Homo_sapiens.NCBI36.53.pep.all.fa 1

Attribution: Taken from https://orthomcl.org/orthomcl/app/downloads/software/v2.0/, orthomclAdjustFasta script

";
exit(1);
}
