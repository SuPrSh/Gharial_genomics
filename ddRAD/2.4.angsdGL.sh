#!/bin/bash

#Note: ANGSD script for population structure analysis with maf filter 
#---- paths
DIR="rmDup" #deduplicated reads
OUTDIR="varCall"
REF="reference.fa.gz"
BAMLIST="${DIR}/listBams"
PREFIX="${OUTDIR}/ggan.filter"

#---- run ANGSD 
ANGSD="angsd path"
echo "Filtering..."
$ANGSD -b "$BAMLIST" -ref "$REF" -out "$PREFIX" \
  -nThreads "$NCPU" \
  -remove_bads 1 -only_proper_pairs 1 -baq 1 -uniqueOnly 1 -trim 0 -C 50 \
  -minMapQ 30 -minQ 30 -minInd 16 -setMinDepthInd 1 -setMaxDepth 84 \
  -doCounts 1 -skipTriallelic 1 -GL 1 -doMajorMinor 1 -doMaf 1 -minMaf 0.05 -SNP_pval 1e-6 2>&1 | tee "${PREFIX}.run.log"
echo "Done."
