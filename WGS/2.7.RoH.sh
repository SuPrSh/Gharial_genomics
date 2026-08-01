#!/bin/bash
#---- 2.7.RoH.sh
#---- Runs of Homozygosity (ROH) and inbreeding coefficient (FROH) estimation
#---- using bcftools roh on the filtered WGS variant set from
#---- 2.4.variantCalling&Filtering.sh

#---- paths / naming
GENOME_GZ="reference.faa.gz"
FILTER_DIR="varFilter"
PREFIX="wgs"
ROH_DIR="roh"

VCF_IN="${FILTER_DIR}/${PREFIX}.filtered.recode.vcf.gz"
AF_FILE="${ROH_DIR}/${PREFIX}.af.tab.gz"
ROH_OUT="${ROH_DIR}/${PREFIX}.roh.txt"
ROH_BED="${ROH_DIR}/${PREFIX}.roh_segments.bed"
FROH_OUT="${ROH_DIR}/${PREFIX}.froh.tsv"

MIN_GQ=30              # -G, minimum genotype quality
THREADS=8

mkdir -p "${ROH_DIR}"

#---- 1. genome length (autosomes/scaffolds used for calling), from .fai ----
echo "computing genome length from ${GENOME_GZ%.gz}.fai"
GENOME_LEN=$(awk '{sum+=$2} END {print sum}' "${GENOME_GZ%.gz}.fai")

#---- 2. compute per-site allele frequencies from the cohort VCF for --AF-file ----
echo "computing allele frequencies for ${AF_FILE}"
bcftools +fill-tags "${VCF_IN}" -Ou -- -t AF \
    | bcftools query -f '%CHROM\t%POS\t%REF,%ALT\t%INFO/AF\n' \
    | bgzip -c > "${AF_FILE}"
tabix -s1 -b2 -e2 "${AF_FILE}"

#---- 3. run bcftools roh using cohort allele frequencies ----
echo "running bcftools roh on ${VCF_IN}"
bcftools roh --threads "${THREADS}" \
    -G "${MIN_GQ}" \
    --AF-file "${AF_FILE}" \
    -o "${ROH_OUT}" \
    "${VCF_IN}"

#---- 4. extract ROH segments (RG lines) as BED ----
echo "extracting ROH segments"
grep "^RG" "${ROH_OUT}" \
    | awk 'BEGIN{OFS="\t"} {print $3, $4, $5, $2, $6}' \
    > "${ROH_BED}"

#---- 5. FROH = sum(ROH length) / genome length ----
echo "calculating FROH per sample"
awk -v glen="${GENOME_LEN}" 'BEGIN{OFS="\t"; print "sample","roh_sum_bp","froh"} \
    {sum[$4]+=$5} \
    END {for (s in sum) print s, sum[s], sum[s]/glen}' "${ROH_BED}" \
    | sort -k1,1 \
    > "${FROH_OUT}"

cat "${FROH_OUT}"

echo "Done."
