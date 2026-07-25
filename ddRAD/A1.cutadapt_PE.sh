#!/bin/bash
set -euo pipefail

TIMESTAMP=$(date +%Y-%m-%d_%Hh%Mm%Ss)
NCPU="${1:-24}"

RR="input.dir"
OUT="output.dir"
LOGDIR="10.log_files"
ADP="adapters.fasta"

mkdir -p "$OUT" "$LOGDIR"

# create sample list from R1 files
find "$RR" -maxdepth 1 -name "*.R1.fastq.gz" -print0 \
| xargs -0 -n1 basename \
| sed 's/\.R1\.fastq\.gz$//' \
| sort -u \
| parallel -j "$NCPU" --linebuffer \
  'cutadapt \
    -a file:'"$ADP"' \
    -A file:'"$ADP"' \
    -o '"$OUT"'/{.}.R1.trim.fastq.gz \
    -p '"$OUT"'/{.}.R2.trim.fastq.gz \
    -e 0.2 -m 50 \
    '"$RR"'/{.}.R1.fastq.gz '"$RR"'/{.}.R2.fastq.gz \
    > '"$LOGDIR"'/'"$TIMESTAMP"'_{.}_cutadapt.log 2>&1'
