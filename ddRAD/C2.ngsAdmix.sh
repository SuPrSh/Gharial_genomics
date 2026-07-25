#!/bin/bash
#Note: NGSadmix script for population structure analysis
#---- paths
INDIR="angsd/pca"
OUTDIR="angsd/admix"
INFILE="${INDIR}/ggan_angsd_pca.r3.step2.beagle.gz"
NGSADMIX="NGSadmix"

mkdir -p "$OUTDIR"
echo "Running admix..."
for K in {2..10}; do
    $NGSADMIX -likes "$INFILE" -K $K -P 24 -minMaf 0.05 -minInd 16 \
        -o "${OUTDIR}/ggan_ngsAdmix_${K}_out"
done
echo "Done"
