#!/usr/bin/env bash
set -euo pipefail

# Usage:
# ./bwa_mem_align_reads_local.sh 8

GENOMEFOLDER="/home/dell/data/sps/ddRAD/refGenome/gavGan"
GENOME_GZ="GCA_030020295.1_rGavGan2.hap2_genomic.fna.gz"

DATAFOLDER="/home/dell/data/sps/ddRAD/9.stacks/03.processedRadtags"
OUTFOLDER="/home/dell/data/sps/ddRAD/9.stacks/4.bam"

mkdir -p "$OUTFOLDER"

# ---- check tools exist locally ----
command -v bwa >/dev/null || { echo "ERROR: bwa not found in PATH"; exit 1; }
command -v samtools >/dev/null || { echo "ERROR: samtools not found in PATH"; exit 1; }

# ---- prepare reference (unzip once + index once) ----
REF_FA="$GENOMEFOLDER/${GENOME_GZ%.gz}"

if [[ ! -f "$REF_FA" ]]; then
  echo "Unzipping reference -> $REF_FA"
  gunzip -c "$GENOMEFOLDER/$GENOME_GZ" > "$REF_FA"
fi

if [[ ! -f "${REF_FA}.bwt" ]]; then
  echo "Indexing reference with bwa index..."
  bwa index "$REF_FA"
fi

# ---- align paired reads ----
shopt -s nullglob

# Try both naming conventions: *R1*.fastq.gz and *_1*.fastq.gz
R1_FILES=( "$DATAFOLDER"/*.R1.trim.fq.gz "$DATAFOLDER"/*_1*.fastq.gz )

if [[ ${#R1_FILES[@]} -eq 0 ]]; then
  echo "ERROR: No R1 files found in $DATAFOLDER"
  exit 1
fi

for r1 in "${R1_FILES[@]}"; do
  # infer R2
  if [[ "$r1" == *R1* ]]; then
    r2="${r1/R1/R2}"
    base=$(basename "$r1")
    sample="${base%%R1*}"
  else
    r2="${r1/_1/_2}"
    base=$(basename "$r1")
    sample="${base%%_1*}"
  fi

  # clean sample string
  sample="${sample%_}"
  sample="${sample%.}"
  [[ -f "$r2" ]] || { echo "ERROR: Missing R2 for $r1 (expected $r2)"; exit 1; }

  echo "Aligning sample: $sample"
  RG="@RG\tID:${sample}\tSM:${sample}\tPL:ILLUMINA"

  outbam="$OUTFOLDER/${sample}.sorted.bam"

  bwa mem -t "$NCPU" -R "$RG" "$REF_FA" "$r1" "$r2" \
    | samtools view -b -q 1 -F 4 -F 256 -F 2048 - \
    | samtools sort -@ "$NCPU" -o "$outbam" -

  samtools index "$outbam"
done

echo "DONE. Sorted BAMs are in: $OUTFOLDER"
