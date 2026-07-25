#!/bin/bash
#---- paths
GENOME_GZ="reference.faa.gz"
TRIM_DIR="trimmed"
ALIGN_DIR="readalignment"
DEDUP_DIR="rmDup"
VARCALL_OUTDIR="varCall"
PREFIX="ddRAD"
THREADS=48

mkdir -p "$ALIGN_DIR" "$VARCALL_OUTDIR/temp" logs

#---- reference unzip and index
REF_FA="${GENOME_GZ%.gz}"

echo "Unzipping reference -> $REF_FA"
gunzip -c "$GENOME_GZ" > "$REF_FA"

echo "Indexing reference with bwa index..."
bwa index "$REF_FA"

#---- align paired reads
R1_FILES=( "$TRIM_DIR"/*.R1.trim.fq.gz "$TRIM_DIR"/*_1*.fastq.gz )
sample=$(basename "$r1" .R1.trim.fq.gz)
echo "Aligning sample: $sample"
    RG="@RG\tID:${sample}\tSM:${sample}\tPL:ILLUMINA"
    outbam="$ALIGN_DIR/${sample}.sorted.bam"
    bwa mem -t "$THREADS" -R "$RG" "$REF_FA" "$r1" "$r2" \
        | samtools view -b -q 1 -F 4 -F 256 -F 2048 - \
        | samtools sort -@ "$THREADS" -o "$outbam" -

    samtools index "$outbam"

#---- mark and remove PCR duplicates ----
    echo "Marking/removing duplicates: $sample"
    rmdupbam="$DEDUP_DIR/${sample}.rmdup.bam"
    metrics="$ALIGN_DIR/${sample}.rmdup_metrics.txt"

    picard -Xmx128g MarkDuplicates \
        I="$outbam" \
        O="$rmdupbam" \
        M="$metrics" \
        REMOVE_DUPLICATES=true

    samtools index -@ "$THREADS" "$rmdupbam"
done

echo "Alignment and deduplication complete. BAMs are in: $DEDUP_DIR"
