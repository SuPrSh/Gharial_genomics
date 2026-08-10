#!/bin/bash
input_dir="rawReads"
output_dir="cleanReads"
report_dir="readqc/fastp"
mkdir -p "$output_dir" "$report_dir"

for R1 in "$input_dir"*.R1.fastq.gz; do
  sample=$(basename "$R1" ".R1.fastq.gz")
  R2="$input_dir${sample}.R2.fastq.gz"
  [ -f "$R2" ] || { echo "Missing R2 for $sample, skipping"; continue; }

  fastp -i "$R1" -I "$R2" \
        -o "${output_dir}${sample}_clean.R1.fastq.gz" \
        -O "${output_dir}${sample}_clean.R2.fastq.gz" \
        -h "${report_dir}${sample}_fastp.html" \
        -j "${report_dir}${sample}_fastp.json" \
        --detect_adapter_for_pe -w 4 -e 30 -q 20
done
