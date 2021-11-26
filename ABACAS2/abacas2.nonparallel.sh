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

### Modified by José Luis Ruiz to improve performance and to be used as part of the ILRA pipeline in 2022. Check out the changelog to get a broad overview of the updates

reference=$1
contig=$2
cores=$3
ABA_MIN_LENGTH=$4
ABA_MIN_IDENTITY=$5
ABA_DO_BLAST=$6

### Make sure that perl finds the libraries
PERL5LIB=$(dirname "$0"):$PERL5LIB; export PERL5LIB
echo -e "We are adding to PERL5LIB the directory $(dirname "$0")..."


### Help
if [ -z "$contig" ] || [ -z "$reference" ] || [ -z "$ABA_MIN_LENGTH" ] ; then
	echo "

*** Abacas II ***       For any disturbation with this program, please don't blame Sammy!

### Usage
abacas2.nonparallel.sh <Reference> <Contigs to order> <Cores>. Optional: <Min aligment length> <Identity cutoff> <Do BLAST>

Reference:           Fasta (or multi-fasta) against which the contigs should be ordered
Contigs:             Contigs or query that should be ordered
Cores		     Cores to use (if 0 is provided, all available cores are used)
Min aligment length: Alignment length significance threshold (default 200)
Identity cutoff:     Threshold for identity to place contigs (default 95)
Do BLAST:	     Does BLAST for the ACT comparison (by default, 1). It can be changed to 0 to deactivate

### Further parameters via environmental variables:
ABA_CHECK_OVERLAP=1; export ABA_CHECK_OVERLAP	# This will try to overlap contigs
ABA_splitContigs=1; export ABA_splitContigs	# This will split contigs. This is good to split the orign, and to find rearrangement. A split contigs has the suffix _i (i the part)
ABA_WORD_SIZE=20; export ABA_WORD_SIZE		# This sets the word size. This is critical for speed issues in nucmer. Default is 20
ABA_COMPARISON=nucmer; export ABA_COMPARISON	# This sets nucmer as the comparison method to use (default). It can be changed to 'promer'
ABA_SPLIT_PARTS=10; export ABA_SPLIT_PARTS	# The files will be processed in parallel and using this number of simultanous processess when possible. By default, 10
ABA_LOW_MEM=yes; export ABA_LOW_MEM		# This sets low memory mode and no parallel processing is going to be performed, by default is deactivated
Check the script 'abacas2.showACT.sh' if you want to automatically check the comparisons in the Artemis Comparison Tool (ACT)

### Results
Results are all files beginning with 'Res.*'. This includes GFF files for contig placements, coverage plots to be loaded into Artemis, FASTA sequences for each contiguated pseudochromosome and the 'Res.abacasBin.fna' file for all input sequences that could not be mapped to the reference (aka the 'bin').

### License
ABACAS2 is released under GPL3.

### Citation
PMID: 19497936
"
	exit;
fi


### Check and set arguments by default if not provided
if [ -z "$ABA_MIN_LENGTH" ] ; then
        ABA_MIN_LENGTH=200; export ABA_MIN_LENGTH
fi
if [ -z "$ABA_MIN_IDENTITY" ] ; then
        ABA_MIN_IDENTITY=95; export ABA_MIN_IDENTITY
fi
if [ -z "$ABA_CHECK_OVERLAP" ] ; then
        ABA_CHECK_OVERLAP=0; export ABA_CHECK_OVERLAP
fi
if [ -z "$ABA_SPLIT_PARTS" ] ; then
        ABA_SPLIT_PARTS=10
fi
if [ "$cores" -eq 0 ]; then
	cores=$(nproc) # If cores=0, use all cores available by default
fi
if [ -z "$ABA_LOW_MEM" ] ; then
        ABA_LOW_MEM="no"; export ABA_LOW_MEM
        cores_split=$((cores / ABA_SPLIT_PARTS)) # subset of cores for the simultaneous processing
elif [ $ABA_LOW_MEM == "no" ]; then
	cores_split=$((cores / ABA_SPLIT_PARTS)) # subset of cores for the simultaneous processing
fi
if [ "$cores_split" -eq 0 ]; then
	cores_split=1 # At least each contig in a core if the number of contigs is exceeding the number of cores
fi
if [ "$ABA_MIN_IDENTITY" -gt "99" ] ; then
	echo "Your identity might be too high $ABA_MIN_IDENTITY > 99 "
	exit;
fi
if [ -z "$ABA_COMPARISON" ] ; then
        ABA_COMPARISON="nucmer"; export ABA_COMPARISON
fi
if [ -z "$ABA_DO_BLAST" ] ; then
        ABA_DO_BLAST=1; export ABA_DO_BLAST
fi

tmp=$$
sed 's/|/_/g' $reference > Ref.$tmp
reference=Ref.$tmp
ln -sf $contig Contigs.$tmp
contig=Contigs.$tmp
export ABA_MIN_LENGTH ABA_MIN_IDENTITY contig reference


### ABACAS2 runComparison
echo -e "\nExecuting abacas2.runComparison.sh...\n"
abacas2.runComparison.sh $reference $contig $cores $ABA_splitContigs
arr=($(find . -name "*.coords" -exec basename {} \; | grep -v Contigs)); length_arr=${#arr[@]}
echo -e "\nDONE\n"


### ABACAS2 TillingGraph
echo -e "\nExecuting abacas2.doTilingGraph.pl...\n"
if [[ $ABA_LOW_MEM == "no" ]] ; then
	echo -e "\nProcessing abacas2.doTilingGraph simultaneously in blocks of at most $cores elements, please decrease the number of cores if running into memory issues...\n"
	count1=1; block=0
	while [ $count1 -le $length_arr ]; do
		count2=1
		(
		while [ $count2 -le $cores ] && [ $count1 -le $length_arr ]; do
			abacas2.doTilingGraph.pl ${arr[$count1 - 1]} $contig Res &
			echo "sequence=${arr[$((count1 - 1))]}"
			(( count1++ ))
			(( count2++ ))
			echo "count1=$count1"; echo "count2=$count2"
		done
		(( block++ ))
		echo "block=$block"; echo -e "\n"
		) 2>&1 | cat -u >> abacas2.doTilingGraph.pl_parallel_log_out.txt
		eval $(grep "count1=" abacas2.doTilingGraph.pl_parallel_log_out.txt | tail -1)
		eval $(grep "block=" abacas2.doTilingGraph.pl_parallel_log_out.txt | tail -1)
	done
elif [[ $ABA_LOW_MEM == "yes" ]] ; then
	for x in "${arr[@]}" ; do
		abacas2.doTilingGraph.pl $x $contig Res
	done
fi
echo -e "\nDONE\n"


### ABACAS2 binning
# abacas2.bin.sh $contig Res.abacasBin.fna && grep -v '>'  Res.abacasBin.fna | awk 'BEGIN {print ">Bin.union"} {print}' > Res.abacasBin.oneSeq.fna_ && cat Res*fna > Genome.abacas.fasta && bam.correctLineLength.sh Genome.abacas.fasta  &> /dev/null && mv  Res.abacasBin.fna_ Res.abacasBin.fna
# JLRuiz update 2022. The line above is the original one in Abacas. However, there was always an error regarding the last statement: "mv Res.abacasBin.fna_ Res.abacasBin.fna"
# It seems "Res.abacasBin.fna_" had never been defined, nor "Res.abacasBin.fna" seemed to be used after that attempted mv command. I'm not sure on the aim, but I have commented the original line and added the same without the last mv statement so we avoid the errors
# In any case, the contigs that are identified in the bin by abacas2 are included in the output sequences, just not merged into a single one. If this is something desirable, here is where the code has to be modified
echo -e "\nExecuting abacas2.bin.sh...\n"
abacas2.bin.sh $contig Res.abacasBin.fna
grep -v '>' Res.abacasBin.fna | awk 'BEGIN {print ">Bin.union"} {print}' > Res.abacasBin.oneSeq.fna_
cat Res*fna > Genome.abacas.fasta
bam.correctLineLength.sh Genome.abacas.fasta &> /dev/null
echo -e "\nDONE\n"


### Blasting:
if [ "$ABA_DO_BLAST" -eq 1 ]; then
	echo -e "\nExecuting MegaBLAST...\n"
	# Preparation:
	ref=$reference; pre=Res; tmp=$$; ln -sf $ref REF.$tmp
	mkdir -p Reference; cd Reference; SeparateSequences.pl ../REF.$tmp; cd ..; mkdir -p comp
	# Execution:
	if [[ $ABA_LOW_MEM == "no" ]] ; then
		count1=1; block=0
		echo -e "\nProcessing formatdb simultaneously in blocks of at most $cores elements, please decrease the number of cores if running into memory issues...\n"
		while [ $count1 -le $length_arr ]; do
			count2=1 
			(
			while [ $count2 -le $cores ] && [ $count1 -le $length_arr ]; do
				element=${arr[$count1 - 1]}; element=${element%.*}
				formatdb -p F -i Reference/$element &
				echo "sequence=$element"
				(( count1++ ))
				(( count2++ ))
				echo "count1=$count1"; echo "count2=$count2"
			done
			(( block++ ))
			echo "block=$block"; echo -e "\n"
			) 2>&1 | cat -u >> formatdb_parallel_log_out.txt
			eval $(grep "count1=" formatdb_parallel_log_out.txt | tail -1)
			eval $(grep "block=" formatdb_parallel_log_out.txt | tail -1)
		done
		
		count1=1; block=0
		echo -e "\nProcessing MegaBLAST simultaneously in blocks of at most $ABA_SPLIT_PARTS elements, please manually change and export the environmental variable 'ABA_SPLIT_PARTS' if required, for example if running into memory issues or less cores available...\n"
		while [ $count1 -le $length_arr ]; do
			count2=1
			(
			while [ $count2 -le $ABA_SPLIT_PARTS ] && [ $count1 -le $length_arr ]; do
				element=${arr[$count1 - 1]}; element=${element%.*}
				megablast -F T -m 8 -e 1e-20 -d Reference/$element -i $pre.$element.fna -a $cores_split -o comp/comp.$element.blast &
				echo "sequence=$element"
				(( count1++ ))
				(( count2++ ))
				echo "count1=$count1"; echo "count2=$count2"
			done
			(( block++ ))
			echo "block=$block"; echo -e "\n"
			) 2>&1 | cat -u >> megablast_parallel_log_out.txt
			eval $(grep "count1=" megablast_parallel_log_out.txt | tail -1)
			eval $(grep "block=" megablast_parallel_log_out.txt | tail -1)
		done
	elif [[ $ABA_LOW_MEM == "yes" ]] ; then
		for nameRes in "${arr[@]}" ; do
			# let count++;
			# if [ $count -gt 200 ] ; then
			#	echo "too many contigs to bsub!\n";
			#	exit
			# fi
			formatdb -p F -i Reference/$nameRes
			megablast -F T -m 8 -e 1e-20 -d Reference/$nameRes -i $pre.$nameRes.fna -a $cores -o comp/comp.$nameRes.blast
		done
	fi
fi
echo -e "\nDONE\n"
