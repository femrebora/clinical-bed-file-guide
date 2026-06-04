# 04 — Create a panel BED file (GRCh37 / hg19), step by step

This is the full, beginner-friendly walkthrough for building a targeted gene-panel BED file from scratch using an **Ensembl GRCh37** reference. You can either run the **one-command script** or follow the **manual steps** to understand exactly what happens.

> The example gene list (`data/example_gene_list.txt`) contains arbitrary public genes for demonstration only — replace it with your own list (see [`03_gene_selection.md`](03_gene_selection.md)).

---

## What you need

| Item | Notes |
|------|-------|
| `Homo_sapiens.GRCh37.dna.primary_assembly.fa.gz` | The GRCh37/hg19 reference **sequence** (Ensembl style). |
| `Homo_sapiens.GRCh37.87.gtf.gz` | The matching **annotation** (downloaded automatically). |
| `data/example_gene_list.txt` | The gene list (one symbol per line). |
| `samtools`, `bedtools`, `wget`, `python3` | Installed and on your `PATH`. |

```bash
sudo apt update
sudo apt install samtools bedtools wget python3
```

> **Why a GTF and not just the FASTA?** The FASTA contains only DNA letters — it has **no gene or exon coordinates**. The **GTF annotation** is what tells you *where* each exon is. You need both: the GTF for exon positions, and the FASTA index for chromosome lengths (so padding can't run past a chromosome end).

---

## Option A — the one-command script (recommended)

```bash
bash scripts/make_panel_bed_grch37.sh Homo_sapiens.GRCh37.dna.primary_assembly.fa.gz
```

This runs all nine steps below and writes the final file **`PANEL.GRCh37.exons.plus20bp.bed`**. Then validate:

```bash
bash scripts/validate_bed_file.sh PANEL.GRCh37.exons.plus20bp.bed
```

To use a different gene list, set `GENE_LIST`:

```bash
GENE_LIST=data/my_panel_genes.txt \
  bash scripts/make_panel_bed_grch37.sh Homo_sapiens.GRCh37.dna.primary_assembly.fa.gz
```

---

## Option B — manual steps (to understand the pipeline)

### Step 1 — Set up a working folder

```bash
mkdir -p PANEL_BED_GRCh37
cd PANEL_BED_GRCh37
# place Homo_sapiens.GRCh37.dna.primary_assembly.fa.gz here
```

### Step 2 — Create the gene list

One **official HGNC symbol** per line (these are arbitrary examples — use your own):

```bash
cat > panel_genes.txt <<'EOF'
TP53
BRCA1
BRCA2
CFTR
EGFR
EOF
```

### Step 3 — Download the matching Ensembl GRCh37 GTF

```bash
wget https://ftp.ensembl.org/pub/grch37/release-87/gtf/homo_sapiens/Homo_sapiens.GRCh37.87.gtf.gz
```

This file holds the gene, transcript, and exon positions for GRCh37.

### Step 4 — Uncompress and index the reference FASTA

```bash
gunzip -c Homo_sapiens.GRCh37.dna.primary_assembly.fa.gz > Homo_sapiens.GRCh37.dna.primary_assembly.fa
samtools faidx Homo_sapiens.GRCh37.dna.primary_assembly.fa
```

`samtools faidx` produces a `.fai` index listing each chromosome and its length.

### Step 5 — Build `genome.txt` (chromosome sizes)

```bash
cut -f1,2 Homo_sapiens.GRCh37.dna.primary_assembly.fa.fai > genome.txt
```

`bedtools slop` uses `genome.txt` so padded intervals never extend **past** the end of a chromosome.

### Step 6 — Extract exon coordinates for your genes

```bash
python3 ../scripts/extract_gene_exons_from_ensembl_gtf.py \
    --gtf    Homo_sapiens.GRCh37.87.gtf.gz \
    --genes  panel_genes.txt \
    --output PANEL.GRCh37.exons.raw.bed
```

The script reads the GTF, keeps only `exon` rows whose `gene_name` is in your list, and converts **1-based GTF** coordinates to **0-based BED** coordinates:

```
bed_start = gtf_start - 1
bed_end   = gtf_end
```

Output is **BED6**: `chrom  start  end  gene_name  score  strand`, e.g.

```
17	7565096	7565332	TP53	0	-
17	41196311	41197819	BRCA1	0	-
```

### Step 7 — Sort the BED file

```bash
sort -k1,1 -k2,2n PANEL.GRCh37.exons.raw.bed > PANEL.GRCh37.exons.sorted.bed
```

Sorting (by chromosome, then numeric start) is required for `bedtools merge` to work correctly.

### Step 8 — Add 20 bp splice padding

```bash
bedtools slop \
    -i PANEL.GRCh37.exons.sorted.bed \
    -g genome.txt \
    -b 20 \
    > PANEL.GRCh37.exons.plus20bp.raw.bed
```

Each region becomes `20 bp + exon + 20 bp`. This captures **splice-region** variants just outside the coding exon, which matter clinically.

### Step 9 — Merge overlapping intervals

```bash
sort -k1,1 -k2,2n PANEL.GRCh37.exons.plus20bp.raw.bed \
  | bedtools merge -i - -c 4 -o distinct \
  > PANEL.GRCh37.exons.plus20bp.bed
```

Padding often makes neighbouring exons overlap; `bedtools merge` collapses them into single, non-redundant intervals. `-c 4 -o distinct` keeps the gene name(s) for each merged region.

**Final file:** `PANEL.GRCh37.exons.plus20bp.bed`

---

## The pipeline at a glance

```
gene list ─┐
           ├─► extract exons (GTF, 1-based ➜ BED 0-based)  ─► raw.bed
GTF ───────┘
                                                   │ sort
                                                   ▼
                                              sorted.bed
                                                   │ slop +20bp  (needs genome.txt from .fai)
                                                   ▼
                                          plus20bp.raw.bed
                                                   │ sort | merge
                                                   ▼
                                  ★ PANEL.GRCh37.exons.plus20bp.bed ★
```

---

## Verify the result

```bash
head PANEL.GRCh37.exons.plus20bp.bed
wc -l PANEL.GRCh37.exons.plus20bp.bed
cut -f1 PANEL.GRCh37.exons.plus20bp.bed | sort -u   # expect 7, 13, 17, ... (no 'chr')
bash ../scripts/validate_bed_file.sh PANEL.GRCh37.exons.plus20bp.bed
```

A ready-made illustrative example is at [`../examples/PANEL.GRCh37.exons.plus20bp.example.bed`](../examples/PANEL.GRCh37.exons.plus20bp.example.bed).

---

## Optional — convert to UCSC (`chr`) naming

Only if your BAM/VCF uses `chr1, chr2, …`:

```bash
awk 'BEGIN{OFS="\t"} {if($1=="MT") $1="chrM"; else if($1 !~ /^chr/) $1="chr"$1; print}' \
    PANEL.GRCh37.exons.plus20bp.bed > PANEL.GRCh37.exons.plus20bp.chr.bed
```

If you are staying with the Ensembl GRCh37 reference, **keep the no-`chr` version**.

---

**Next:** [`05_validate_bed_files.md`](05_validate_bed_files.md) — validate thoroughly before you trust it.
