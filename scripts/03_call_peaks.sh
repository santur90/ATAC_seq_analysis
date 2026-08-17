#!/usr/bin/env bash
set -euo pipefail

samples=$1
bamdir=$2
outdir=$3
genome_size=$4
fragment_length=$5

mkdir -p "$outdir"
while IFS=$'\t' read -r sample condition replicate r1 r2; do
    [[ "$sample" == "sample" || -z "$sample" ]] && continue
    bam="$bamdir/${sample}.filtered.bam"
    [[ -f "$bam" ]] || { echo "BAM missing for $sample: $bam" >&2; exit 1; }

    macs3 callpeak \
        -t "$bam" \
        -f BAMPE \
        -g "$genome_size" \
        -n "$sample" \
        --outdir "$outdir" \
        --nomodel \
        --shift -100 \
        --extsize "$fragment_length" \
        --keep-dup all \
        --call-summits \
        --qvalue 0.05 \
        2> "$outdir/${sample}.macs3.log"
done < "$samples"
