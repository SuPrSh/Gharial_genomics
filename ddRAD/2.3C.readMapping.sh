#!/bin/bash
#---- paths
    GENOME_GZ="reference.fa.gz"
    TRIM_DIR="trimmedReads"
	ALIGN_DIR="readAlignment"
	DEDUP_DIR="rmDup"
	VARCALL_OUTDIR="varCall"
	PREFIX="ddRAD"
	THREADS=48

mkdir -p "$ALIGN_DIR" "$VARCALL_OUTDIR/temp"

#---- reference unzip and index
REF_FA="${GENOME_GZ%.gz}"

echo "Unzipping reference -> $REF_FA"
gunzip -c "$GENOME_GZ" > "$REF_FA"

echo "Indexing reference with bwa index..."
bwa index "$REF_FA"

#---- align, mark/remove duplicates
for r1 in "$TRIM_DIR"/*.R1.trim.fq.gz; do
    sample=$(basename "$r1" .R1.trim.fq.gz)
    r2="$TRIM_DIR/${sample}.R2.trim.fq.gz"
    [ -f "$r2" ] || { echo "Missing R2 for $sample, skipping"; continue; }

    outbam="$ALIGN_DIR/${sample}.sorted.bam"
    bwa mem -t "$THREADS" -R "@RG\tID:${sample}\tSM:${sample}\tPL:ILLUMINA" "$REF_FA" "$r1" "$r2" \
        | samtools view -b -q 1 -F 4 -F 256 -F 2048 - \
        | samtools sort -@ "$THREADS" -o "$outbam" -
    samtools index "$outbam"

    echo "Marking/removing duplicates: $sample"
    rmdupbam="$DEDUP_DIR/${sample}.rmdup.bam"
    metrics="$ALIGN_DIR/${sample}.rmdup_metrics.txt"
    picard -Xmx96g MarkDuplicates \
        I="$outbam" \
        O="$rmdupbam" \
        M="$metrics" \
        REMOVE_DUPLICATES=true
    samtools index -@ "$THREADS" "$rmdupbam"
done
echo "Alignment and deduplication complete. BAMs are in: $DEDUP_DIR"
