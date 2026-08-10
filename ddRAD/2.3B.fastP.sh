#!/bin/bash
RT="processedRadtags"
TR="trimmedReads"
RD="readqc/fastp"

mkdir -p "$TR" "$RD"

for R1 in "$RT"*.R1.fastq.gz; do
  sample=$(basename "$R1" ".R1.fastq.gz")
  R2="$RT${sample}.R2.fastq.gz"
  [ -f "$R2" ] || { echo "Missing R2 for $sample, skipping"; continue; }

  fastp -i "$R1" -I "$R2" \
        -o "${TR}${sample}.R1.trim.fq.gz" \
        -O "${TR}${sample}.R2.trim.fq.gz" \
        -h "${TR}${sample}_fastp.html" \
        -j "${RD}${sample}_fastp.json" \
        --detect_adapter_for_pe -w 4 -e 30 -q 20
done
