#!/bin/bash
#Note: Admixture script for population structure analysis
#---- paths
INDIR="angsd/plink"
OUTDIR="angsd/admix"
ADMIX="admixture"

mkdir -p "$OUTDIR"

#----loops for running admixture at each K for 10 runs per k
#----Defining the file name
prefix="ggan.admix"
#----first loop to run admixture r number of times for each value of K
    for r in {1..10}
    do
#----second loop to run admixture for different values of K
	    for K in {2..10}
	    do
#----cv option will do cross-validation to find the best K value from the output log file
	    $ADMIX --cv -s ${RANDOM} ./${prefix}.bed ${K} | tee $OUTDIR/log${prefix}K${K}r${r}.out
	    mv ./${prefix}.${K}.Q ./admixtureOutput/${prefix}.K${K}r${r}.Q
	    done
    done
echo "Done"
