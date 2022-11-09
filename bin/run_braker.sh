#!/bin/bash

genome=$1
annProt=$2
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
echo "${args[@]}"
braker.pl --genome=$genome --prot_seq=$annProt --gff3 --cores $cores "${args[@]}"
