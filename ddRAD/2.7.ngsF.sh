
#!/bin/bash
#---- paths
DIR="angsd/03.resultGL"
OUT_DIR="ngsF/03.results"
PREFIX="ngsF"
NIND=21

mkdir -p "$OUT_DIR" logs
#cd "$DIR"

#---- get number of sites from the mafs file (site count = line count minus header) ----
NSITES=$(zcat $DIR/${PREFIX}.forNgsF.mafs.gz | tail -n +2 | wc -l)
echo "N individuals: $NIND"
echo "N sites: $NSITES"

#---- decompress glf ----
zcat $DIR/${PREFIX}.forNgsF.glf.gz > $DIR/${PREFIX}.forNgsF.glf

#---- run ngsF (approximate EM) ----
ngsF --n_ind $NIND --n_sites $NSITES --glf $DIR/${PREFIX}.forNgsF.glf #--min_epsilon 1e-9 \
     --out $OUT_DIR/${PREFIX}.approx_indF --approx_EM --init_values r \
     --n_threads 16

#---- run ngsF (approximate EM) ----
ngsF --n_ind $NIND --n_sites $NSITES --glf $DIR/${PREFIX}.forNgsF.glf -min_epsilon 1e-6 \
     --out $OUT_DIR/${PREFIX}.indF --init_values $OUT_DIR/${PREFIX}.approx_indF.pars \
     --n_threads "$SLURM_CPUS_PER_TASK"
echo "Done."

echo "Done."
