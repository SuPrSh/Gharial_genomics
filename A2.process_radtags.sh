#!/bin/bash
set -euo pipefail

TIMESTAMP=$(date +%Y-%m-%d_%Hh%Mm%Ss)

TR="03.trimmed"
LF="10.log_files"
RT="03.processedRadtags"

# Create output folders
mkdir -p "$LF" "$RT"

for r1 in "$TR"/*.R1.trim.fastq.gz
do
sample=$(basename "$r1" .R1.trim.fastq.gz)
    r2="$TR/${sample}.R2.trim.fastq.gz"

echo "Processing $sample"

process_radtags -P \
        -1 "$r1" \
        -2 "$r2" \
        -o "$RT" \
        --clean --quality --rescue \
        --renz_1 mspI --renz_2 pstI \
        --disable_rad_check \
        2>&1 | tee "$LF/${sample}.process_radtags.log"

done
