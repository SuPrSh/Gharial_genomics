#!/bin/bash
#---- 2.8.snpEff.sh
#---- Build custom snpEff database for Gavialis gangeticus and annotate
#---- the filtered WGS variant set from 2.4.variantCalling&Filtering.sh

#---- paths / naming
GENOME_GZ="reference.faa.gz"          # same reference used for mapping/calling
GFF_GZ="annotation.gff.gz"            # matching GFF3 annotation (GCF_001723915.1)
FILTER_DIR="varFilter"
PREFIX="wgs"
DB_NAME="Gavialis_gangeticus"

SNPEFF_DIR="snpEff"
SNPEFF_DATA="${SNPEFF_DIR}/data/${DB_NAME}"
SNPEFF_CONFIG="${SNPEFF_DIR}/snpEff.config"
ANNOT_DIR="snpEffAnnotation"

VCF_IN="${FILTER_DIR}/${PREFIX}.filtered.recode.vcf.gz"
VCF_OUT="${ANNOT_DIR}/${PREFIX}.filtered.ann.vcf"

MEM="16g"

mkdir -p "${SNPEFF_DATA}" "${ANNOT_DIR}"

#---- 1. stage genome and annotation ----
echo "staging genome and annotation for ${DB_NAME}"
zcat "${GENOME_GZ}" > "${SNPEFF_DATA}/sequences.fa"
zcat "${GFF_GZ}" > "${SNPEFF_DATA}/genes.gff"

#---- 2. register custom genome in snpEff.config ----
echo "registering ${DB_NAME} in snpEff.config"
cp "$(dirname "$(readlink -f "$(command -v snpEff)")")/snpEff.config" "${SNPEFF_CONFIG}"
printf "\n# Gavialis gangeticus (gharial) custom genome\n%s.genome : %s\n" "${DB_NAME}" "${DB_NAME}" >> "${SNPEFF_CONFIG}"

#---- 3. build snpEff database ----
echo "building snpEff database: ${DB_NAME}"
snpEff build -Xmx${MEM} -c "${SNPEFF_CONFIG}" -dataDir "$(realpath "${SNPEFF_DIR}/data")" \
    -gff3 -v "${DB_NAME}" 2> "${ANNOT_DIR}/${DB_NAME}.build.log"

#---- 4. annotate filtered VCF ----
echo "annotating ${VCF_IN}"
snpEff ann -Xmx${MEM} -c "${SNPEFF_CONFIG}" -dataDir "$(realpath "${SNPEFF_DIR}/data")" \
    -v -stats "${ANNOT_DIR}/${PREFIX}.snpEff_summary.html" \
    -csvStats "${ANNOT_DIR}/${PREFIX}.snpEff_summary.csv" \
    "${DB_NAME}" "${VCF_IN}" > "${VCF_OUT}" \
    2> "${ANNOT_DIR}/${PREFIX}.snpEff_ann.log"

bgzip -f "${VCF_OUT}"
bcftools index -t "${VCF_OUT}.gz"

#---- 5. extract flat annotation table ----
echo "extracting annotation table"
SnpSift extractFields "${VCF_OUT}.gz" \
    CHROM POS REF ALT \
    "ANN[0].GENE" "ANN[0].GENEID" "ANN[0].EFFECT" "ANN[0].IMPACT" \
    "ANN[0].FEATURE" "ANN[0].HGVS_C" "ANN[0].HGVS_P" \
    > "${ANNOT_DIR}/${PREFIX}.snpEff_annotationTable.tsv"

#---- 6. impact summary ----
echo "impact category counts:"
zcat "${VCF_OUT}.gz" \
    | grep -oP 'ANN=[^;]+' \
    | awk -F'|' '{print $3}' \
    | sort | uniq -c | sort -rn \
    > "${ANNOT_DIR}/${PREFIX}.impact_summary.txt"
cat "${ANNOT_DIR}/${PREFIX}.impact_summary.txt"

echo "Done."
