#!/bin/bash
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

contig=$1
resultName=$2
pre=$3

if [ -z "$pre" ] ; then
	pre=Res
fi

grep Contig $pre.*.contigs.gff | perl -nle '/label=\"\S*contig=(\S+)\";note/;print $1' > List.mappingcontig.fofn

Assembly.deleteContigs.pl List.mappingcontig.fofn $contig $resultName
rm -f List.mappingcontig.fofn
