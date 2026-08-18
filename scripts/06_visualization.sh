#!/usr/bin/env bash
set -euo pipefail

samples=$1
bamdir=$2
outdir=$3
effective_genome_size=$4
threads=$5
fragment_length=$6

mkdir -p "$outdir/bigwig" "$outdir/figures"
while IFS=$'\t' read -r sample _ _ _ _; do
    [[ "$sample" == "sample" || -z "$sample" ]] && continue
    bam="$bamdir/${sample}.filtered.bam"
    [[ -f "$bam" ]] || continue
    shifted_bam="$outdir/${sample}.ATACshift.bam"
    alignmentSieve \
        --bam "$bam" \
        --ATACshift \
        --outFile "$shifted_bam" \
        --numberOfProcessors "$threads"
    samtools index -@ "$threads" "$shifted_bam"
    bamCoverage \
        --bam "$shifted_bam" \
        --outFileName "$outdir/bigwig/${sample}.CPM.ATACshift.bw" \
        --outFileFormat bigwig \
        --normalizeUsing CPM \
        --effectiveGenomeSize "$effective_genome_size" \
        --binSize 25 \
        --extendReads "$fragment_length" \
        --numberOfProcessors "$threads"
done < "$samples"
