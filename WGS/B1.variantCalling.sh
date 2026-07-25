#!/bin/bash
#---- paths
GENOME_GZ="reference.faa.gz"
TRIM_DIR="trimmed"
ALIGN_DIR="readalignment"
VARCALL_OUTDIR="varCall"
PREFIX="wgs"
THREADS=48

mkdir -p "$ALIGN_DIR" "$VARCALL_OUTDIR/temp" logs

#---- index reference genome
echo "indexing reference genome"
bwa index "$GENOME_GZ"

#---- align single sample (paired-end)
echo "aligning reads"
bwa mem -t "$THREADS" "$GENOME_GZ" \
    "${TRIM_DIR}/wgs_r1_trim.fastq.gz" \
    "${TRIM_DIR}/wgs_r2_trim.fastq.gz" \
    | samtools view -O BAM - \
    | samtools sort -T "${ALIGN_DIR}/temp" -O bam -o "${ALIGN_DIR}/${PREFIX}.sorted.bam" -

#---- mark and remove PCR duplicates
echo "marking-removing duplicates"
picard -Xmx128g MarkDuplicates \
    I="${ALIGN_DIR}/${PREFIX}.sorted.bam" \
    O="${PREFIX}.rmdup.bam" \
    M="${PREFIX}.rmdup_metrics.txt" \
    REMOVE_DUPLICATES=true

samtools index -@ "$THREADS" "${PREFIX}.rmdup.bam"

#---- variant calling
echo "variant calling"
bcftools mpileup -Q 30 -q 30 -C 50 -A -Ou --threads "$THREADS" \
    -f "$GENOME_GZ" "${PREFIX}.rmdup.bam" \
    | bcftools call -c -Ov -o "${PREFIX}_variants.vcf"

echo "Done."
