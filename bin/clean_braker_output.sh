#!/bin/bash

braker_out=$1
cleaned=$2

gffread $braker_out | awk '$3=="transcript" || $3=="gene"' > missing_transcripts
cat missing_transcripts $braker_out | gt gff3 -sort -tidy | gt uniq > $cleaned
