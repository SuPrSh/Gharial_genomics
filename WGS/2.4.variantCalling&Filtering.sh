#!/bin/bash
#---- paths
GENOME_GZ="reference.faa.gz"
TRIM_DIR="trimmed"
DEDUP_DIR="rmDup"
VARCALL_DIR="varCall"
FILTER_DIR="varFilter"
PREFIX="wgs"
THREADS=48

mkdir -p "$VARCALL_DIR/temp" "$FILTER_DIR"

#---- prepare reference ----
REF_FA="${GENOME_GZ%.gz}"
if [ ! -f "$REF_FA" ]; then
    echo "Unzipping reference -> $REF_FA"
    gunzip -c "$GENOME_GZ" > "$REF_FA"
fi
if [ ! -f "${REF_FA}.fai" ]; then
    samtools faidx "$REF_FA"
fi

#---- variant calling ----
echo "variant calling"
ls "${DEDUP_DIR}"/*.rmdup.bam > "${DEDUP_DIR}/listBams"

bcftools mpileup --threads "$THREADS" -Ou -f "$REF_FA" \
    -q 30 -Q 30 -a FORMAT/DP,FORMAT/AD \
    --bam-list "${DEDUP_DIR}/listBams" \
    | bcftools call --threads "$THREADS" -Ou -c -f GQ \
    | bcftools sort --temp-dir "${VARCALL_DIR}/temp" -Oz \
    -o "${VARCALL_DIR}/${PREFIX}.vcf.gz"

bcftools index -t "${VARCALL_DIR}/${PREFIX}.vcf.gz"

#---- VCF filtering ----
echo "filtering VCF"

#---- keep biallelic SNPs ----
vcftools --gzvcf "${VARCALL_DIR}/${PREFIX}.vcf.gz" \
    --max-alleles 2 --min-alleles 2 \
    --out "${FILTER_DIR}/step1" --recode

#---- depth, genotype quality, site quality ----
vcftools --vcf "${FILTER_DIR}/step1.recode.vcf" \
    --minDP 15 --maxDP 147 --minGQ 30 --minQ 30 \
    --out "${FILTER_DIR}/${PREFIX}.filtered" --recode

bgzip -f "${FILTER_DIR}/${PREFIX}.filtered.recode.vcf"
bcftools index -t "${FILTER_DIR}/${PREFIX}.filtered.recode.vcf.gz"

echo "Done"
