#!/usr/bin/env perl
# Copyright (c) 2011-2015 Genome Research Ltd.
# Author: Thomas D. Otto <tdo@sanger.ac.uk>
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

use strict;
use warnings;

if (scalar(@ARGV)<2) {
  die "call prog <list> <fasta> <resultName>\n";

}
my $refha_list = getList(shift);

my $res;

my $fastq=shift;

my $result=getFasta($fastq,$refha_list);

my $ResultName=shift;

#my $result=getFasta($fastq,$refha_list);

open F,"> $ResultName " or die "Problem $ResultName: $!";
print F $result;
close(F);

sub getFastq{
  my $name = shift;
  my $list = shift;

  open F, $name or die "$name not set \n";

  my $res;

  while (<F>) {
	chomp;
	/^@(\S+)/;
	if (! defined($$list{$1})) {
	  $res.= "$_\n";
	  foreach (1..3) {

		$res.=<F>;

	  }
	}

	else {
	  #throw the rest away
	  $_=<F>;$_=<F>;$_=<F>;
	}

  }
  return $res;
}

sub getFasta{
  open F, shift;
 my $list = shift;

  my %h;
  my $res;
  my $keep=0;

  while (<F>) {
	chomp;
	if (/^>(\S+)/){
	  if (! defined($$list{$1})) {
		$res.="$_\n";
		$keep=1;
	  }
	  else {
		$keep=0
	  }
	}
	elsif ($keep==1) {
	  $res.=$_."\n";
	}
  }

  return $res;
}

sub getList{
  my $name = shift;

  open F, $name or die "Couldn't open file $name:$! \n\n\n\\n\n\n";

  my %h;
  my @F=<F>;
  keys (%h) = (1.2*scalar(@F));

#  while (<F>) {
  foreach (@F) {
	if (defined($_) && $_ ne "") {

	  my @ar=split(/\s+/);
	  if (defined($ar[0])) {
		$h{$ar[0]}=1;
	  }

	}

  }

  return \%h;
}

