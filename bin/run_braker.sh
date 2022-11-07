#!/bin/bash

genome=$1
annProt=$2
augustusModelPath=$3
cores=$4
useExisting=$5
isFungi=$6
isSoftmasked=$7

if [ "$isFungi" == "true" ]
then
    args+=(--fungus)
fi
if [ "$isSoftmasked" == "true"]
then
    args+=(--softmasking)
fi
if [ "$useExisting" == "true" ]
then
    args+=(--species=augustus_species)
    args+=(--useexisting)
    AUGUSTUS_CONFIG_PATH=$augustusModelPath; export AUGUSTUS_CONFIG_PATH 
fi
echo "${args[@]}"
braker.pl --genome=$genome --prot_seq=$annProt --gff3 --cores $cores --augustus_args=\"--singlestrand=true\" "${args[@]}"
