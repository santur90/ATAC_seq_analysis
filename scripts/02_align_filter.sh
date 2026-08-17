#!/usr/bin/env bash
set -euo pipefail

samples=$1
index=$2
trimmed=$3
outdir=$4
threads=$5
min_mapq=$6
remove_duplicates=$7
unique_only=$8
mitochondrial_chrom=$9
blacklist=${10:-}

mkdir -p "$outdir/intermediate" "$outdir/logs"
while IFS=$'\t' read -r sample condition replicate r1 r2; do
    [[ "$sample" == "sample" || -z "$sample" ]] && continue
    read1="$trimmed/${sample}_R1.fastq.gz"
    read2="$trimmed/${sample}_R2.fastq.gz"
    sam="$outdir/intermediate/${sample}.unsorted.sam"
    name_sorted="$outdir/intermediate/${sample}.name_sorted.bam"
    fixmate="$outdir/intermediate/${sample}.fixmate.bam"
    coordinate_sorted="$outdir/intermediate/${sample}.coordinate_sorted.bam"
    filtered_bam="$outdir/${sample}.filtered.bam"
    [[ -f "$read1" && -f "$read2" ]] || { echo "Trimmed reads missing for $sample" >&2; exit 1; }

    bowtie2 --very-sensitive-local -x "$index" -1 "$read1" -2 "$read2" -p "$threads" -S "$sam" \
        2> "$outdir/logs/${sample}.bowtie2.log"
    samtools view -@ "$threads" -h -q "$min_mapq" -F 4 "$sam" \
        | awk -v unique="$unique_only" -v mito="$mitochondrial_chrom" 'BEGIN { OFS="\t" } /^@/ { print; next } $3 == mito { next } { has_xs=0; for (i=12; i<=NF; i++) if ($i ~ /^XS:/) has_xs=1; if (unique != "true" || has_xs == 0) print }' \
        | samtools view -@ "$threads" -b - \
        | samtools sort -@ "$threads" -n -o "$name_sorted" -

    samtools fixmate -@ "$threads" -m "$name_sorted" "$fixmate"
    samtools sort -@ "$threads" -o "$coordinate_sorted" "$fixmate"
    if [[ "$remove_duplicates" == "true" ]]; then
        samtools markdup -@ "$threads" -r "$coordinate_sorted" "$filtered_bam"
    else
        cp "$coordinate_sorted" "$filtered_bam"
    fi
    if [[ -n "$blacklist" ]]; then
        [[ -f "$blacklist" ]] || { echo "Blacklist BED not found: $blacklist" >&2; exit 1; }
        bedtools intersect -v -abam "$filtered_bam" -b "$blacklist" > "$outdir/${sample}.blacklist_filtered.bam"
        mv "$outdir/${sample}.blacklist_filtered.bam" "$filtered_bam"
    fi
    samtools index -@ "$threads" "$filtered_bam"
    samtools flagstat -@ "$threads" "$filtered_bam" > "$outdir/${sample}.flagstat.txt"
    samtools stats "$filtered_bam" > "$outdir/${sample}.stats.txt"
done < "$samples"
