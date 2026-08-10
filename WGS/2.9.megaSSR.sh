#!/bin/bash
#---- 2.9.misa.sh
#---- Genome-wide SSR (microsatellite) mining and marker design with MegaSSR
#---- on the WGS reference assembly used for mapping/calling

#---- paths / naming
GENOME_GZ="reference.fa.gz"
GFF_GZ="annotation.gff.gz"
PREFIX="wgs"
OUTDIR="megaSSR"

MEGASSR="MegaSSR.sh path"
THREADS=8

#---- SSR / primer design parameters (min repeat units mono..hexa, compound
#---- distance, primer size range, product size range, flank length)
MIN_MONO=20
MIN_DI=6
MIN_TRI=5
MIN_TETRA=4
MIN_PENTA=3
MIN_HEXA=3
COMPOUND_DIST=100
PRIMER_MIN=18
PRIMER_OPT=20
PRODUCT_MIN=100
PRODUCT_MAX=500
FLANK_LEN=1000
BLAST="no"

mkdir -p "${OUTDIR}"

#---- 1. unzip genome and annotation ----
echo "unzipping genome and annotation"
gunzip -k -f "${GENOME_GZ}"
gunzip -k -f "${GFF_GZ}"

#---- 2. package as .zip inputs (MegaSSR expects zipped FASTA/GFF) ----
echo "packaging FASTA and GFF as .zip inputs"
zip -j "${OUTDIR}/${PREFIX}.fna.zip" "${GENOME_GZ%.gz}"
zip -j "${OUTDIR}/${PREFIX}.gff.zip" "${GFF_GZ%.gz}"

#---- 3. run MegaSSR: SSR mining, genic/non-genic classification, primer design ----
echo "running MegaSSR"
bash "${MEGASSR}" \
    -A 2 \
    -F "${OUTDIR}/${PREFIX}.fna.zip" \
    -G "${OUTDIR}/${PREFIX}.gff.zip" \
    -P "${OUTDIR}/${PREFIX}" \
    -1 "${MIN_MONO}" -2 "${MIN_DI}" -3 "${MIN_TRI}" \
    -4 "${MIN_TETRA}" -5 "${MIN_PENTA}" -6 "${MIN_HEXA}" \
    -C "${COMPOUND_DIST}" \
    -s "${PRIMER_MIN}" -O "${PRIMER_OPT}" \
    -R "${PRODUCT_MIN}-${PRODUCT_MAX}" \
    -L "${FLANK_LEN}" \
    -B "${BLAST}" \
    -t "${THREADS}"

echo "Done."
