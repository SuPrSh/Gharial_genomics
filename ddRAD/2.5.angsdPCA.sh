#!/bin/bash

# Note: angsd script for genotype calling with posterior probability for PCA
#---- paths
DIR="rmDup"
REF="reference.fa.gz"
OUTDIR="angsd/pca"
SNP="Global_SNPList.txt"
ANGSD="angsd.path"
BAMLIST="$DIR/listBams"
PREFIX="$OUTDIR/ggan_angsd_pca"

mkdir -p "$OUTDIR"

#----run angsd
$ANGSD -P "$NCPU" -b "$BAMLIST" -anc "$REF" -out "$PREFIX" \
	-GL 1 -doGlf 2 -doMajorMinor 3 -doMAF 1 -doPost 1 \
	-doIBS 1 -doCounts 1 -doCov 1 -makeMatrix 1 -sites "$SNP" \
	-minInd 16 -minMaf 0.05
