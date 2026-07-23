#!/usr/bin/env bash
set -euo pipefail

# Usage:
# ./bwa_mem_align_reads_local.sh 8

GENOMEFOLDER="reference.genome.dir"
GENOME_GZ="reference.faa.gz"

DATAFOLDER="data.dir"
OUTFOLDER="out.dir"

mkdir -p "$OUTFOLDER"

# ---- prepare reference (unzip once + index once) ----
REF_FA="$GENOMEFOLDER/${GENOME_GZ%.gz}"
echo "Unzipping reference -> $REF_FA"
    gunzip -c "$GENOMEFOLDER/$GENOME_GZ" > "$REF_FA"
echo "Indexing reference with bwa index..."
    bwa index "$REF_FA"

# ---- align paired reads ----
R1_FILES=( "$DATAFOLDER"/*.R1.trim.fq.gz "$DATAFOLDER"/*_1*.fastq.gz )
echo "Aligning sample: $sample"
RG="@RG\tID:${sample}\tSM:${sample}\tPL:ILLUMINA"
outbam="$OUTFOLDER/${sample}.sorted.bam"
  bwa mem -t "$NCPU" -R "$RG" "$REF_FA" "$r1" "$r2" \
    | samtools view -b -q 1 -F 4 -F 256 -F 2048 - \
    | samtools sort -@ "$NCPU" -o "$outbam" -

  samtools index "$outbam"
done

echo "DONE. Sorted BAMs are in: $OUTFOLDER"
