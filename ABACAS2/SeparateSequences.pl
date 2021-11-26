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

### will cut a fasta in individual files with the name >(\S*) A$
# ARGV[1] will say how much sequences...
SeparateSequences($ARGV[0],$ARGV[1]);
sub SeparateSequences{
  my $FileName = shift;
  my $Amount = shift;

  if (!defined($Amount)) {
	$Amount = 99999999999;
  }
  open (FILE, $FileName) or die "Couldn't open file to Separate $FileName $!\n";

  my $Counter = 0;
  my $Out;
  my @NameFiles;
  while (<FILE>) {
	if ($Counter < $Amount) {

	  if (/^>(\S+)/) {
		print $_,"\n";

		close(FILEOUT);
		my $Name = $1;#."_$Counter.fasta";
		open (FILEOUT, "> $Name") or die "Problem do $Name file  $!\n";
		push @NameFiles, $Name;
		$Counter++;
		print FILEOUT $_;
	  }
	  else {
		print FILEOUT $_;
	  }
	}
  }
  print "$Counter Sequences where generated\nDone.\n";
  return \@NameFiles;
}
