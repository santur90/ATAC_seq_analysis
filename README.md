# ATAC_seq_analysis

A reproducible, sample-sheet-driven ATAC-seq workflow for paired-end sequencing data. The workflow is designed for workstation or HPC execution and keeps intermediate files, filtering decisions, QC metrics, peak calls, and visualization tracks organized by stage.

## Workflow

`FASTQ -> FastQC/fastp -> Bowtie2 alignment -> MAPQ/unique/duplicate/mitochondrial filtering -> MACS3 ATAC peaks -> TSS and fragment QC -> replicate consistency -> signal tracks`

## Quick start

```bash
cd atacseq_pipeline
mamba env create -f environment.yml
mamba activate atacseq

# Edit config.tsv and samples.tsv before running.
./run_atacseq.sh --config config.tsv --samples samples.tsv --threads 8
```

Use a dry run to inspect all commands:

```bash
./run_atacseq.sh --config config.tsv --samples samples.tsv --dry-run
```

## Input files

`config.tsv` contains project-level paths and parameters. `samples.tsv` contains one row per ATAC-seq library:

| sample | condition | replicate | fastq_r1 | fastq_r2 |
|---|---|---:|---|---|
| atac_control_rep1 | control | 1 | data/atac_control_rep1_R1.fastq.gz | data/atac_control_rep1_R2.fastq.gz |
| atac_treat_rep1 | treat | 1 | data/atac_treat_rep1_R1.fastq.gz | data/atac_treat_rep1_R2.fastq.gz |

## Configuration

1. Set `BOWTIE2_INDEX` to the Bowtie2 index prefix for the correct genome assembly.
2. Set `GENOME_SIZE` and `EFFECTIVE_GENOME_SIZE` for the organism.
3. Set `MITOCHONDRIAL_CHROM` to the chromosome name used by the reference, such as `chrM` or `MT`.
4. Set `BLACKLIST_BED` to a genome-version-matched blacklist BED file, or leave it as `NONE`.
5. Set `REGIONS_BED` to a TSS or other genomic regions BED file to enable TSS enrichment plots, or leave it as `NONE`.
6. Adjust `TSS_UPSTREAM`, `TSS_DOWNSTREAM`, `MIN_MAPQ`, and `FRAGMENT_LENGTH` for the experiment.

ATAC-seq does not use an Input library for peak calling. The default MACS3 configuration uses paired-end fragments with `--shift -100 --extsize 200`, which is appropriate as a starting point for Tn5 insertion data and should be reviewed for each assay.

## Outputs

- `results/qc/`: FastQC, fastp, MultiQC, fragment-size summaries, and TSS enrichment plots
- `results/bam/`: intermediate SAM/BAM files, final filtered/indexed BAM files, and alignment metrics
- `results/peaks/`: MACS3 narrowPeak, summit, and peak table files
- `results/replicates/`: peak overlaps and optional IDR output
- `results/bigwig/`: CPM-normalized and Tn5-shifted signal tracks
- `results/visualization/`: signal matrices, profiles, and heatmaps when `REGIONS_BED` is configured

## Quality review

Review read quality, alignment rate, mitochondrial fraction, duplication rate, fragment-size distribution, TSS enrichment, FRiP, blacklist overlap, and replicate concordance before interpreting peaks. All coordinate files must use the same genome assembly.

## Repository layout

```text
atacseq_pipeline/
├── config.tsv
├── samples.tsv
├── environment.yml
├── run_atacseq.sh
└── scripts/
    ├── 01_qc_trim.sh
    ├── 02_align_filter.sh
    ├── 03_call_peaks.sh
    ├── 04_atac_qc.sh
    ├── 05_replicate_consistency.sh
    └── 06_visualization.sh
```
