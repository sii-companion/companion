#!/usr/bin/env perl
# Copyright (c) 2011-2015 Genome Research Ltd.
# Author: Martin Hunt <mh12@sanger.ac.uk>
#
# This file is part of ABACAS2.
#
# ABACAS2 is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later
# version.
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
# details.
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <http://www.gnu.org/licenses/>.

# takes a one-line-per-sequence fasta and converts to the evil multi-line format

use strict;
use warnings;

if ( @ARGV != 3){
    print "Usage: fasta2multipleLine.pl <input fasta file> <output fasta file> <line width>\n";
	print "Fasta has to be single lined\n" ;
    exit;
}

my $infile     = $ARGV[0];
my $outfile    = $ARGV[1];
my $line_width = $ARGV[2];

my $out_string = "";
my $tmp_string;

my %contig_seq = () ;
my @contig_names = () ;


print "Reading contigs\n" ;
open (IN, "$infile") or die "oops!\n" ;
while (<IN>) {

    # print "$_" ;

    if (/^>(\S+)/) {

	my $seq_name = $1 ;
	my $seq = <IN> ;
	chomp($seq) ;

	$contig_seq{$seq_name} = $seq ;
	push(@contig_names, $seq_name) ;
    }

}
close(IN) ;


open F, ">", $outfile or die "Error opening $outfile";


foreach my $contig_name (@contig_names) {

	my $seq = $contig_seq{$contig_name} ;

	print "Doing $contig_name\n" ;

	print F ">$contig_name\n" ;

	my $seq_len = length($seq) ;
	my $times = int($seq_len / $line_width) ;
	my $remainder = $seq_len % $line_width ;

	print "$seq_len $times\n" ;

	my $coords = 0 ;
	for (my $i = 0 ; $i < $times ; $i++ ) {
            my $out_string .= substr($seq,$coords,$line_width) . "\n";
		$coords += $line_width ;
            print F "$out_string" ;
        }
	if ($remainder != 0 ) {
        	my $out_string .= substr($seq,$coords,$line_width) . "\n";
        	print F "$out_string" ;
	}

}


close F;



