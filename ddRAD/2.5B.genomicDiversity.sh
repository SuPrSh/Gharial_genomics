#!/bin/bash

#--Note: ANGSD/realSFS/thetaStat script for nucleotide diversity (pi), Watterson's theta, and Tajima's D from ddRAD site allele frequencies
#---- paths
DIR="rmDup"
REF="reference.fa.gz"
OUTDIR="angsd/diversity"
ANGSD="angsd.path"
REALSFS="realSFS.path"
THETASTAT="thetaStat.path"
BAMLIST="$DIR/listBams"
PREFIX="$OUTDIR/ggan.diversity"

mkdir -p "$OUTDIR"

#---- site allele frequency likelihoods ----
echo "Calculating site allele frequency likelihoods..."
$ANGSD -P "$NCPU" -b "$BAMLIST" -anc "$REF" -ref "$REF" -out "$PREFIX" \
	-GL 1 -doSaf 1 -remove_bads 1 -only_proper_pairs 1 -baq 1 -uniqueOnly 1 \
	-minMapQ 30 -minQ 30 -minInd 16 -setMinDepthInd 1 -setMaxDepth 84

#---- folded site frequency spectrum ----
echo "Estimating folded SFS..."
$REALSFS "$PREFIX.saf.idx" -fold 1 -P "$NCPU" > "$PREFIX.sfs"

#---- per-site theta estimates ----
echo "Calculating per-site thetas..."
$REALSFS saf2theta "$PREFIX.saf.idx" -sfs "$PREFIX.sfs" -fold 1 -outnames "$PREFIX"

#---- genome-wide theta summary (pi, Watterson's theta, Tajima's D) ----
echo "Summarizing genome-wide diversity statistics..."
$THETASTAT do_stat "$PREFIX.thetas.idx"

echo "Done."
