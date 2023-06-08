#!/bin/bash

genome=$1
allHints=$2
augustusModelPath=$3
spId=$4
cores=$5
useExisting=$6
isFungi=$7
isSoftmasked=$8

if [ "$isFungi" == "true" ]
then
    args+=(--fungus)
fi
if [ "$isSoftmasked" == "true" ]
then
    args+=(--softmasking)
fi
if [ "$useExisting" == "true" ]
then
    args+=(--species=augustus_species)
    args+=(--useexisting)
    AUGUSTUS_CONFIG_PATH=$augustusModelPath; export AUGUSTUS_CONFIG_PATH
else
    args+=(--species=$spId)
fi

# GeneMark-ES has been known to fail when assembly consists of lots of short contigs. See https://github.com/Gaius-Augustus/BRAKER/issues/426#issuecomment-943430561
maxContigLength=`cat $genome | awk '$0 ~ ">" {print c; c=0;printf substr($0,2,100) "\t"; } $0 !~ ">" {c+=length($0);} END { print c; }' | sort -k2 -h | cut -f2 | tail -1`
if [ "$maxContigLength" -lt "50000" ]
then
    args+=(--min_contig=1000)
fi

echo "${args[@]}"
braker.pl --genome=$genome --hints=$allHints --gff3 --cores $cores "${args[@]}"
