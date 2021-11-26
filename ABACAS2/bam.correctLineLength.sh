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

name=$1

if [ -z "$name" ] ; then
	echo "Please give the (multi-) fasta to be corrected...";
	exit;
fi

tmp=$$
cat $name | perl $(dirname $0)/fasta2singleLine.tdo.pl > $name.$tmp
perl $(dirname $0)/fasta2multipleLine_v2.pl $name.$tmp $name 80
rm $name.$tmp
