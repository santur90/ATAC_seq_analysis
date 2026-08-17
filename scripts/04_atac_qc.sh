#!/usr/bin/env bash
set -euo pipefail

samples=$1
bamdir=$2
outdir=$3
regions_bed=${4:-}
upstream=$5
downstream=$6
threads=$7

mkdir -p "$outdir/fragment_size" "$outdir/tss"
while IFS=$'\t' read -r sample condition replicate r1 r2; do
    [[ "$sample" == "sample" || -z "$sample" ]] && continue
    bam="$bamdir/${sample}.filtered.bam"
    [[ -f "$bam" ]] || { echo "BAM missing for $sample: $bam" >&2; exit 1; }
    bamPEFragmentSize \
        --bamfiles "$bam" \
        --histogram "$outdir/fragment_size/${sample}.png" \
        --outRawFragmentLengths "$outdir/fragment_size/${sample}.tsv" \
        --maxFragmentLength 1000 \
        --numberOfProcessors "$threads"
done < "$samples"

if [[ -z "$regions_bed" ]]; then
    echo "REGIONS_BED is empty; TSS enrichment analysis skipped."
    exit 0
fi
[[ -f "$regions_bed" ]] || { echo "Regions BED not found: $regions_bed" >&2; exit 1; }
shopt -s nullglob
bam_files=("$bamdir"/*.filtered.bam)
[[ "${#bam_files[@]}" -gt 0 ]] || { echo "No filtered BAM files found in $bamdir" >&2; exit 1; }
computeMatrix reference-point \
    --referencePoint TSS \
    -b "$upstream" -a "$downstream" \
    -R "$regions_bed" \
    -S "${bam_files[@]}" \
    --binSize 10 \
    --skipZeros \
    -o "$outdir/tss/TSS_matrix.gz" \
    --outFileSortedRegions "$outdir/tss/TSS_regions.sorted.bed" \
    -p "$threads"
plotProfile \
    -m "$outdir/tss/TSS_matrix.gz" \
    -out "$outdir/tss/TSS_enrichment_profile.png" \
    --perGroup \
    --refPointLabel TSS \
    --plotTitle "ATAC-seq TSS enrichment"
