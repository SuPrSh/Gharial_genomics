#!/bin/bash

#----paths
RAW="rawReads"
QC_RAW="fastQC"
TR="trimmedReads"
QC_REPORT="readqc/fastp"

mkdir -p "$QC_RAW" "$TR" "$QC_REPORT"

#---- FastQC on raw reads
fastqc -t 8 -o "$QC_RAW" "$RAW"/*.fastq.gz

#---- fastp: Q30 base trimming + adapter removal
for r1 in "$RAW"/*.R1.fastq.gz; do
    sample=$(basename "$r1" .R1.fastq.gz)
    r2="$RAW/${sample}.R2.fastq.gz"
    [ -f "$r2" ] || { echo "Missing R2 for $sample, skipping"; continue; }

    fastp -i "$r1" -I "$r2" \
          -o "$TR/${sample}.R1.trim.fq.gz" -O "$TR/${sample}.R2.trim.fq.gz" \
          --detect_adapter_for_pe \
          -h "$QC_REPORT/${sample}_fastp.html" -j "$QC_REPORT/${sample}_fastp.json" \
          -w 8
done
