#!/bin/bash

#----paths
BAM="wgs.dedup.bam"
VCF="wgs.psmc.vcf"
OUTDIR="psmc_results"
PREFIX="gharial"
THREADS=32


#----variables
MU=0.8e-8          # mutation rate per site per generation
GEN_TIME=25         # generation time in years
NBOOT=100
mkdir -p "$OUTDIR" logs
cd "$OUTDIR"

#---- estimate average depth (used to set -d/-D thresholds below)
echo "Estimating average depth"
AVG_DEPTH=$(samtools depth -@ "$THREADS" -aa "../$BAM" | awk '{sum+=$3} END {print sum/NR}')
echo "Average depth: $AVG_DEPTH"

#---- standard PSMC convention: -d = avg_depth/3, -D = avg_depth*2
MIN_DEPTH=$(echo "$AVG_DEPTH / 3" | bc)
MAX_DEPTH=$(echo "$AVG_DEPTH * 2" | bc)
echo "Using -d $MIN_DEPTH -D $MAX_DEPTH"

#----convert VCF to diploid consensus FASTQ
echo "VCF to FASTQ"
vcfutils.pl vcf2fq -d "$MIN_DEPTH" -D "$MAX_DEPTH" "../$VCF" | gzip > "${PREFIX}_psmc.fq.gz"

#----convert FASTQ to PSMC input format (.psmcfa)
echo "FASTQ to PSMCFA"
fq2psmcfa -q 20 "${PREFIX}_psmc.fq.gz" > "${PREFIX}.diploid.psmcfa"

#---- PSMC run
echo "Running PSMC"
psmc -N30 -t5 -r5 -p "4+25*2+4+6" \
    -o "${PREFIX}.main.psmc" \
    "${PREFIX}.diploid.psmcfa"

#----100 bootstrap replicates 
echo "Splitting PSMCFA for bootstrap"
splitfa "${PREFIX}.diploid.psmcfa" > "${PREFIX}.split.psmcfa"
echo "Running $NBOOT bootstrap replicates"
seq "$NBOOT" | parallel -j "$THREADS" --max-args 1 \
    psmc -N30 -t5 -r5 -b -p "4+25*2+4+6" \
    -o "round-{}.psmc" "${PREFIX}.split.psmcfa"

#----combine main run + bootstrap replicates
echo "Combining main + bootstrap runs"
cat "${PREFIX}.main.psmc" round-*.psmc > combined.psmc

#----generate plot
echo "Plotting"
psmc_plot.pl -p -G -g "$GEN_TIME" -u "$MU" "${PREFIX}_psmc_plot" combined.psmc
echo "Done. Final combined file: ${OUTDIR}/combined.psmc"
echo "Plot output prefix: ${PREFIX}_psmc_plot"
