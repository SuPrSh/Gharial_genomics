# Gharial Genomics

Code and analysis scripts accompanying the manuscript: *Genomic signatures of ancient and recent population decline in the Critically Endangered gharial (Gavialis gangeticus)*

## Overview
This repository contains all custom scripts used for variant calling, filtering,
demographic inference, population structure, relatedness, and inbreeding analyses
using whole-genome sequencing (WGS) and ddRAD-seq data from the gharial
(*Gavialis gangeticus*), Chambal River population.

## Data availability
- The datasets supporting the conclusions of this article are available in the NCBI Sequence Read Archive under accession numbers SRR38278210–SRR38278230 and SRR30853456, under BioProjects PRJNA1458109 (https://www.ncbi.nlm.nih.gov/bioproject/PRJNA1458109) and PRJNA1167702 (https://www.ncbi.nlm.nih.gov/bioproject/?term=PRJNA1167702). 
- Reference genome: GCA_030020295.1 (rGavGan2.hap2),
  https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/030/020/295/GCA_030020295.1_rGavGan2.hap2/

## Repository structure
Folders are numbered to match the corresponding Methods subsections in the manuscript.

```
├── 2.3 Quality check and reads mapping/
│   ├── WGS/
│   │   ├── 2.3A.readqc_trimming.sh
│   │   └── 2.3B.readMapping.sh
│   └── ddRAD/
│       ├── 2.3A.process_radtags.sh
│       ├── 2.3B.fastp.sh
│       └── 2.3C.readMapping.sh
│
├── 2.4 Variant calling and filtering/
│   ├── WGS/
│   │   └── 2.4.variantCalling_Filtering.sh
│   └── ddRAD/
│       └── 2.4.angsdGL.sh
│
├── 2.5 Relatedness, genomic diversity and population genomics structure/
│   └── ddRAD/
│       ├── 2.5A.ngsRelate.sh
│       ├── 2.5B.genomicDiversity.sh
│       ├── 2.5C.angsdPCA.sh
│       └── 2.5C.ngsAdmix.sh
│
├── 2.6 Inference of ancient and contemporary effective population size/
│   ├── WGS/
│   │   └── 2.6.psmc.sh
│   └── ddRAD/
│       └── 2.6.gone.sh
│
├── 2.7 Runs of homozygosity and inbreeding/
│   ├── WGS/
│   │   └── 2.7.RoH.sh
│   └── ddRAD/
│       └── 2.7.ngsF.sh
│
├── 2.8 Functional annotation/
│   └── WGS/
│       └── 2.8.snpEff.sh
│
├── 2.9 Genome-wide microsatellite selection and screening/
│   └── WGS/
│       └── 2.9.megaSSR.sh
│ 
├── Figures/
│   ├── Fig2A.ngsAdmix.R
│   ├── Fig2B.pca.R
│   └── Fig3.PSMC_GONE.R
│
└── README.md
