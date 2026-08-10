#!/bin/bash

#--Note: NgsRelate pairwise relatedness estimation from ddRAD genotype likelihoods and allele frequencies (ANGSD glf3 format)

#---- paths
DIR="rmDup"
OUTDIR="ngsFoutputfile"
REF="reference.fa.gz"
BAMLIST="${DIR}/listBams"
PREFIX="${OUTDIR}/ggan.filter"
NCPU=16

#---- tool paths
ANGSD="angsd path"
NGSRELATE="NgsRelate path"

#---- genotype likelihoods (glf3) + allele frequencies ----
echo "Generating genotype likelihoods and allele frequencies..."
$ANGSD -b "$BAMLIST" -ref "$REF" -out "$PREFIX" \
  -nThreads "$NCPU" \
  -remove_bads 1 -only_proper_pairs 1 -baq 1 -uniqueOnly 1 -trim 0 -C 50 \
  -minMapQ 30 -minQ 30 -minInd 16 -setMinDepthInd 1 -setMaxDepth 84 \
  -doCounts 1 -skipTriallelic 1 -GL 1 -doMajorMinor 1 -doMaf 1 -minMaf 0.05 -SNP_pval 1e-6 \
  -doGlf 3 2>&1 | tee "${PREFIX}.run.log"

#---- allele frequency file for NgsRelate (knownEM column from .mafs.gz) ----
echo "Extracting allele frequencies..."
zcat "${PREFIX}.mafs.gz" | tail -n +2 | cut -f5 > "${PREFIX}.freq"

#---- sample count from BAM list ----
echo "Counting samples..."
N_IND=$(wc -l < "$BAMLIST")

#---- run NgsRelate ----
echo "Running NgsRelate..."
$NGSRELATE -g "${PREFIX}.glf.gz" -n "$N_IND" -f "${PREFIX}.freq" \
  -O "${PREFIX}.ngsRelate" -p "$NCPU"

echo "Done."
