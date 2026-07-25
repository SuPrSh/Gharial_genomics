#!/bin/bash

#----paths
OUTDIR="03.results/r4"
GONE2="GONE2/gone2"
PED="forGONE.ped"
MAP="forGONE.map"

#----variables
PREFIX="forGONE"
NCHR=16
NREPS=15           
DROP_N=1   
PLINK="plink"

mkdir -p "$OUTDIR" logs

for b in $(seq 1 $NREPS); do
    echo "subsample replicate $b (dropping $DROP_N of $NCHR chromosomes)"
    repdir="${OUTDIR}/rep${b}"
    mkdir -p "$repdir"

    #----randomly choose DROP_N chromosomes to exclude this replicate (no replacement)
    dropped=$(shuf -n $DROP_N -i 1-$NCHR --random-source=<(openssl enc -aes-256-ctr -pass pass:"sub${b}" -nosalt </dev/zero 2>/dev/null))

    #----build list of chromosomes to KEEP (comma-separated for plink --chr)
    kept=$(comm -23 <(seq 1 $NCHR | sort) <(echo "$dropped" | sort) | paste -sd,)

    #---- extract kept chromosomes directly from PED/MAP using plink
    $PLINK --file "${OUTDIR}/${PREFIX}" \
        --chr $kept \
        --recode --allow-extra-chr \
        --out "${repdir}/rep${b}.raw" 2>&1 | tail -5

    #----renumber kept chromosomes sequentially 1..N
    awk 'BEGIN{OFS="\t"} {print $1}' "${repdir}/rep${b}.raw.map" | sort -un > "${repdir}/kept_chroms.txt"
    awk '{print $0"\t"NR}' "${repdir}/kept_chroms.txt" > "${repdir}/chrom_remap.txt"
    awk 'NR==FNR {map[$1]=$2; next} {$1=map[$1]; print}' \
        "${repdir}/chrom_remap.txt" "${repdir}/rep${b}.raw.map" > "${repdir}/rep${b}.map"
    cp "${repdir}/rep${b}.raw.ped" "${repdir}/rep${b}.ped"

    #---run GONE2 on subset
    cd "$repdir"
    $GONE2 -g 3 -r 0.89 -o rep${b} rep${b}.ped
    cd - > /dev/null

    echo "Replicate $b done (kept $((NCHR-DROP_N)) chromosomes)."
done

echo "All $NREPS chromosome-subsample replicates complete."
