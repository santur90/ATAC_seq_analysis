#!/usr/bin/env bash
set -euo pipefail

samples=$1
peakdir=$2
outdir=$3
idr_threshold=$4

mkdir -p "$outdir"
conditions=$(awk -F '\t' 'NR > 1 {print $2}' "$samples" | sort -u)
while IFS= read -r condition; do
    [[ -n "$condition" ]] || continue
    peak_files=()
    condition_samples=$(awk -F '\t' -v c="$condition" 'NR > 1 && $2 == c {print $1}' "$samples")
    while IFS= read -r sample; do
        [[ -n "$sample" ]] || continue
        peak_file="$peakdir/${sample}_peaks.narrowPeak"
        [[ -f "$peak_file" ]] && peak_files+=("$peak_file")
    done <<< "$condition_samples"

    if [[ "${#peak_files[@]}" -lt 2 ]]; then
        echo "Fewer than two peak sets for condition $condition; replicate comparison skipped."
        continue
    fi
    bedtools intersect -a "${peak_files[0]}" -b "${peak_files[1]}" -wa -wb > "$outdir/${condition}.overlap.narrowPeak"

    if command -v idr >/dev/null 2>&1; then
        sort -k8,8nr "${peak_files[0]}" > "$outdir/${condition}.rep1.sorted.narrowPeak"
        sort -k8,8nr "${peak_files[1]}" > "$outdir/${condition}.rep2.sorted.narrowPeak"
        idr \
            --samples "$outdir/${condition}.rep1.sorted.narrowPeak" "$outdir/${condition}.rep2.sorted.narrowPeak" \
            --input-file-type narrowPeak \
            --rank p.value \
            --idr-threshold "$idr_threshold" \
            --output-file "$outdir/${condition}.idr" \
            --plot \
            --log-output-file "$outdir/${condition}.idr.log"
    else
        echo "idr is not installed; overlap output was generated for $condition."
    fi
done <<< "$conditions"
