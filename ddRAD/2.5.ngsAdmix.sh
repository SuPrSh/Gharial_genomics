#!/bin/bash

#---- paths
INDIR="angsd/pca"
OUTDIR="angsd/admix"
INFILE="${INDIR}/*.beagle.gz"
NGSADMIX="NGSadmix"
NREPS=10

mkdir -p "$OUTDIR" logs

#---- loop to run k 2 to 10 for 10 reps each
for K in {2..10}; do
    for rep in $(seq 1 $NREPS); do
        $NGSADMIX -likes "$INFILE" -K $K -P 8 -minMaf 0.05 -minInd 16 \
            -o "${OUTDIR}/ggan_ngsAdmix_K${K}_rep${rep}"
    done
done
echo "Done"
