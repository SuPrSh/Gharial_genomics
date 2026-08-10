#!/bin/bash
#----paths
RAW="rawReads"
LF="logFiles"
RT="processedRadtags"
mkdir -p "$LF" "$RT"

#----run loop
for r1 in "$RAW"/*R1_001.fastq.gz; do
  sample=$(basename "$r1" _R1_001.fastq.gz)
  r2="$RAW/${sample}_R2_001.fastq.gz"
  [ -f "$r2" ] || { echo "Missing R2 for $sample, skipping"; continue; }

process_radtags -P \
    -1 "$r1" -2 "$r2" \
    -o "$RT" \
    --basename "$sample" \
    --clean --quality --rescue \
    --renz_1 mspI --renz_2 pstI \
    2>&1 | tee "$LF/${sample}.process_radtags.log"
done
