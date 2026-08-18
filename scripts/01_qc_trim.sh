#!/usr/bin/env bash
set -euo pipefail

samples=$1
outdir=$2
threads=$3

mkdir -p "$outdir/raw_fastqc" "$outdir/trimmed" "$outdir/fastp"
while IFS=$'\t' read -r sample _ _ r1 r2; do
    [[ "$sample" == "sample" || -z "$sample" ]] && continue
    [[ -f "$r1" ]] || { echo "Missing R1 for $sample: $r1" >&2; exit 1; }
    [[ -f "$r2" ]] || { echo "Missing R2 for $sample: $r2" >&2; exit 1; }

    fastqc --threads "$threads" --outdir "$outdir/raw_fastqc" "$r1" "$r2"
    fastp \
        --thread "$threads" \
        --in1 "$r1" --in2 "$r2" \
        --out1 "$outdir/trimmed/${sample}_R1.fastq.gz" \
        --out2 "$outdir/trimmed/${sample}_R2.fastq.gz" \
        --html "$outdir/fastp/${sample}.html" \
        --json "$outdir/fastp/${sample}.json" \
        --detect_adapter_for_pe \
        --trim_poly_g \
        --qualified_quality_phred 20 \
        --length_required 20
done < "$samples"
