# clinical-bed-file-guide

A beginner-friendly, technically correct guide to **creating, validating, and using BED files** for targeted gene panels in clinical and research genomics.

This repository walks you from "What is a BED file?" all the way to building a working **targeted gene-panel BED file** from scratch using Ensembl **GRCh37 / hg19** reference data.

---

## Why BED files matter

A **BED file** is a simple text file that lists genomic regions of interest. In targeted sequencing it answers one central question:

> *Which parts of the genome do we care about?*

BED files are used to:

- Define the **target regions** of a gene panel (the genes/exons you want to sequence).
- **Filter** variants so you only keep the ones inside your regions of interest.
- Drive **coverage analysis** (did every target region get enough reads?).
- Restrict **annotation** and reporting to clinically relevant regions.

A small mistake in a BED file — the wrong genome build, the wrong chromosome naming, or a one-base coordinate shift — silently corrupts every downstream step. Getting the BED file right is foundational.

---

## Who this repo is for

- **Beginners** in bioinformatics who have never built a BED file.
- **Clinical genomics users** who receive a kit/manufacturer target BED and want to understand it.
- **Researchers** who need to build a custom gene-panel BED from a list of genes.

No prior BED knowledge is assumed. Every command is copy-paste friendly.

---

## Quick start

```bash
# 1. Clone the repo
git clone https://github.com/<your-username>/clinical-bed-file-guide.git
cd clinical-bed-file-guide

# 2. Read the docs in order (docs/01 ... docs/06)

# 3. Build a panel BED file from your GRCh37 reference FASTA
bash scripts/make_panel_bed_grch37.sh /path/to/Homo_sapiens.GRCh37.dna.primary_assembly.fa.gz

# 4. Validate the result
bash scripts/validate_bed_file.sh PANEL.GRCh37.exons.plus20bp.bed
```

> New to BED files? Start with [`docs/01_what_is_bed_format.md`](docs/01_what_is_bed_format.md) before running anything.

---

## Required tools

| Tool       | Used for                                              | Install (Debian/Ubuntu)        |
|------------|-------------------------------------------------------|--------------------------------|
| `python3`  | Extracting exon coordinates from the GTF              | `sudo apt install python3`     |
| `samtools` | Indexing the reference FASTA (`samtools faidx`)       | `sudo apt install samtools`    |
| `bedtools` | Padding (`slop`) and merging (`merge`) BED intervals  | `sudo apt install bedtools`    |
| `wget`     | Downloading the Ensembl GRCh37 GTF annotation         | `sudo apt install wget`        |

```bash
sudo apt update
sudo apt install python3 samtools bedtools wget
```

---

## Input files needed

| File | What it is | Where to get it |
|------|------------|-----------------|
| `Homo_sapiens.GRCh37.dna.primary_assembly.fa.gz` | The **GRCh37 / hg19** reference genome sequence (Ensembl style: `1, 2, …, X, Y, MT`). | [Ensembl GRCh37](https://grch37.ensembl.org/) |
| `Homo_sapiens.GRCh37.87.gtf.gz` | The matching **annotation** file with gene/transcript/exon coordinates. Downloaded automatically by the build script. | [Ensembl GRCh37 release-87 GTF](https://ftp.ensembl.org/pub/grch37/release-87/gtf/homo_sapiens/Homo_sapiens.GRCh37.87.gtf.gz) |
| A gene list (e.g. `data/example_gene_list.txt`) | One gene symbol per line (HGNC official symbols). | Provided in this repo (replace with your own) |

> **Why both a FASTA and a GTF?**
> The FASTA contains only the **DNA sequence** — it has no idea where genes or exons are. The **GTF annotation** provides the gene and exon **coordinates**. You need both: the GTF to know *where* exons are, and the FASTA index to know how long each chromosome is (so padding does not run off the end).

---

## How to create a panel BED file

The full, beginner-friendly walkthrough is in [`docs/04_create_panel_bed_grch37.md`](docs/04_create_panel_bed_grch37.md). In short:

```bash
bash scripts/make_panel_bed_grch37.sh Homo_sapiens.GRCh37.dna.primary_assembly.fa.gz
```

This single script will:

1. Check that `samtools`, `bedtools`, `wget`, and `python3` are installed.
2. Download `Homo_sapiens.GRCh37.87.gtf.gz` if it is missing.
3. Uncompress and `samtools faidx`-index the reference FASTA.
4. Build `genome.txt` (chromosome sizes) from the FASTA index.
5. Extract exon coordinates for the gene list (via the Python script).
6. Sort the BED intervals.
7. Add **20 bp of splice padding** with `bedtools slop`.
8. Merge overlapping intervals with `bedtools merge`.
9. Write the final file: **`PANEL.GRCh37.exons.plus20bp.bed`**.

> The default list at `data/example_gene_list.txt` contains **arbitrary public example genes** (for demonstration only). Edit it — or pass your own via `GENE_LIST=...` — to build a real panel. See [`docs/03_gene_selection.md`](docs/03_gene_selection.md).

---

## How to validate the final BED file

```bash
bash scripts/validate_bed_file.sh PANEL.GRCh37.exons.plus20bp.bed
```

This checks that:

- The file exists and is non-empty.
- `start` and `end` are numeric.
- `start < end` on every line.
- `start` is never negative.
- It prints the chromosome names used (so you can confirm Ensembl-style `1, 2, …` vs UCSC-style `chr1`).
- It counts the total number of intervals.
- It shows the first 10 lines.

See [`docs/05_validate_bed_files.md`](docs/05_validate_bed_files.md) for the full validation checklist.

---

## Explanation of output files

| File | Description |
|------|-------------|
| `Homo_sapiens.GRCh37.dna.primary_assembly.fa` | Uncompressed reference FASTA. |
| `Homo_sapiens.GRCh37.dna.primary_assembly.fa.fai` | FASTA index produced by `samtools faidx`. |
| `genome.txt` | Two-column file (chromosome, length) used by `bedtools slop`. |
| `Homo_sapiens.GRCh37.87.gtf.gz` | Ensembl GRCh37 annotation (gene/exon coordinates). |
| `PANEL.GRCh37.exons.raw.bed` | Raw BED6 of all exons for the gene list, straight from the GTF. |
| `PANEL.GRCh37.exons.sorted.bed` | The raw BED, sorted by chromosome then start. |
| `PANEL.GRCh37.exons.plus20bp.raw.bed` | Exons padded by 20 bp on each side (pre-merge). |
| **`PANEL.GRCh37.exons.plus20bp.bed`** | **Final file**: sorted, padded, and merged. Use this. |

A ready-made illustrative example is included at [`examples/PANEL.GRCh37.exons.plus20bp.example.bed`](examples/PANEL.GRCh37.exons.plus20bp.example.bed).

---

## ⚠️ Important clinical note

For **true clinical coverage analysis**, the most correct BED file is always the **original target BED from the kit / panel manufacturer**.

A gene-based exon BED (like the one this repo builds) is excellent for **variant filtering, annotation, and approximate region-based analysis**, but it may **not exactly match** a capture or amplicon kit design. Amplicon kits in particular may not cover every exon equally, and the manufacturer target BED reflects the actual probe/primer layout.

> Use the gene-based BED for filtering and exploration. Use the manufacturer target BED for coverage QC and clinical reporting.

---

## Disclaimer

This repository is **educational and for workflow-preparation purposes only**. It is **not** a clinically validated diagnostic pipeline. Nothing here should be used to make clinical decisions without independent validation by qualified personnel in an accredited laboratory, in accordance with local regulatory requirements. Gene lists, coordinates, and example files are provided to teach the workflow — always confirm gene selection and coordinates against authoritative, up-to-date sources before any clinical use.

---

## License

Released under the [MIT License](LICENSE).
