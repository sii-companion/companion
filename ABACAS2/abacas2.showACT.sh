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

chr=$1
path=$2

if [ -z "$path" ] ; then
	if [ -f "embl/$chr.embl" ] ; then
		act embl/$chr.embl comp/comp.$chr.blast <(cat Res.$chr.contigs.gff Res.$chr.fna)
	else
		act Reference/$chr comp/comp.$chr.blast <(cat Res.$chr.contigs.gff Res.$chr.fna)
	fi
else
	### The "first comp of the top genome must be switch, as subject and query are revcomp"
	cat $path/comp/comp.$chr.blast | perl -nle '@ar=split(/\t/);$tmp=$ar[6];$ar[6]=$ar[8];$ar[8]=$tmp;$tmp=$ar[7];$ar[7]=$ar[9];$ar[9]=$tmp;print join("\t",@ar)' > $path/comp/REV.comp.$chr.blast
	if [ -f "embl/$chr.embl" ] ; then
		echo "act <(cat $path/Res.$chr.contigs.gff  $path/Res.$chr.fna) $path/comp/REV.comp.$chr.blast embl/$chr.embl comp/comp.$chr.blast <(cat Res.$chr.contigs.gff Res.$chr.fna)"
		act <(cat $path/Res.$chr.contigs.gff  $path/Res.$chr.fna) $path/comp/REV.comp.$chr.blast embl/$chr.embl comp/comp.$chr.blast <(cat Res.$chr.contigs.gff Res.$chr.fna)
	else
		echo "act <(cat $path/Res.$chr.contigs.gff  $path/Res.$chr.fna) $path/comp/REV.comp.$chr.blast Reference/$chr comp/comp.$chr.blast <(cat Res.$chr.contigs.gff Res.$chr.fna)"
		act <(cat $path/Res.$chr.contigs.gff  $path/Res.$chr.fna) $path/comp/REV.comp.$chr.blast Reference/$chr comp/comp.$chr.blast <(cat Res.$chr.contigs.gff Res.$chr.fna)
	fi
fi
