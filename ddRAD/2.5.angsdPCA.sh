#!/usr/bin/env bash
set -euo pipefail

# Note: angsd script for genotype calling with posterior probability for PCA
# -------- resources --------
NCPU="${1:-24}"   # run: ./run_angsd.sh 32  (optional)

#---- paths
DIR="deduplicated.bams"
REF="reference.faa.gz"
OUTDIR="angsd/pca"
SNP="Global_SNPList.txt"
ANGSD="angsd.path"
BAMLIST="$DIR/listBams.21samp"
PREFIX="$OUTDIR/ggan_angsd_pca.r3"

mkdir -p "$OUTDIR"

$ANGSD -P "$NCPU" -b "$BAMLIST" -anc "$REF" -out "$PREFIX" \
	-GL 1 -doGlf 2 -doMajorMinor 3 -doMAF 1 -doPost 1 \
	-doIBS 1 -doCounts 1 -doCov 1 -makeMatrix 1 -sites "$SNP" \
	-minInd 16 -minMaf 0.05
