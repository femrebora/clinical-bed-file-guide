# 02 — Understanding a clinical target BED file

When a clinic or a kit manufacturer sends you a **target BED file**, it describes the regions the panel is designed to capture/sequence. This page uses an **Alzheimer / Parkinson / Dementia neurodegeneration panel** as a representative example of *what such a file looks like* and *how to inspect it*.

> The repo ships a small **sanitized** stand-in at [`../data/example_clinic_target_sanitized.bed`](../data/example_clinic_target_sanitized.bed). Run the commands below against your own kit BED (or the sanitized example) to follow along.

---

## What a clinical target BED typically contains

- **Many rows** — usually hundreds to thousands of target intervals. A panel covering ~80 genes can easily have **~1,000+ rows**, because each gene contributes multiple exon/target regions.
- **One region per targeted exon (or probe/amplicon)** — not one row per gene.
- **A gene name in column 4** (BED4 is common for clinical kits).
- **A consistent genome build and naming style** — you must know both before using it.

A few representative lines (Ensembl-style naming, BED4; **coordinates below are synthetic, for format illustration only**):

```
1	1000000	1000130	GENEA_EXAMPLE
1	1002500	1002640	GENEA_EXAMPLE
1	1005000	1005120	GENEA_EXAMPLE
1	2000000	2000180	GENEB_EXAMPLE
1	2003000	2003150	GENEB_EXAMPLE
```

Notice that **GENEA_EXAMPLE** appears on several consecutive lines — one per targeted exon.

---

## How to inspect a target BED

### 1. Look at the first lines

```bash
head -n 10 your_kit_target.bed
```

This immediately tells you: how many columns there are (BED3/BED4/BED6), the naming style (`1` vs `chr1`), and whether there is a header/comment line.

### 2. Count the columns

```bash
head -n 1 your_kit_target.bed | awk -F'\t' '{print NF " columns"}'
```

`4 columns` → BED4 (chrom, start, end, gene).

### 3. Count the total regions

```bash
wc -l your_kit_target.bed
```

This is the number of **target intervals**, not the number of genes.

### 4. Count the genes

```bash
cut -f4 your_kit_target.bed | sort -u | wc -l
```

And list them:

```bash
cut -f4 your_kit_target.bed | sort -u
```

For example, a neurodegeneration panel might report **~86 unique genes** across **~1,000 intervals** — i.e. roughly a dozen target regions per gene on average.

### 5. Check the chromosome naming style

```bash
cut -f1 your_kit_target.bed | sort -u
```

If you see `1, 2, …, X, Y` → **Ensembl style** (matches a GRCh37 Ensembl reference).
If you see `chr1, chr2, …` → **UCSC style** (matches a UCSC/`hg19` reference).

This single check prevents one of the most common failures: a BED that silently matches **zero** regions because the naming differs from the BAM/VCF.

### 6. Sanity-check coordinates

```bash
# Should print nothing if all intervals are well-formed:
awk -F'\t' '$2 < 0 || $3 <= $2' your_kit_target.bed
```

---

## Quick reference table

| Question                       | Command                                              |
|--------------------------------|------------------------------------------------------|
| What do the first rows look like? | `head -n 10 file.bed`                             |
| How many columns?              | `head -1 file.bed \| awk -F'\t' '{print NF}'`        |
| How many target regions?       | `wc -l file.bed`                                     |
| How many genes?                | `cut -f4 file.bed \| sort -u \| wc -l`               |
| Which genes?                   | `cut -f4 file.bed \| sort -u`                        |
| Which chromosomes / naming?    | `cut -f1 file.bed \| sort -u`                        |
| Any broken intervals?          | `awk -F'\t' '$2<0 \|\| $3<=$2' file.bed`             |

---

## Why you can't just rebuild it from a gene list

A manufacturer target BED reflects the **actual probe or amplicon design** — which exons are covered, how regions are padded, and which difficult regions are intentionally included or excluded. A gene-based exon BED that you build yourself (the rest of this guide) is a good **approximation** for filtering and annotation, but it is **not identical** to the kit design. For coverage QC and clinical reporting, keep and use the original kit BED. See the clinical note in the [README](../README.md) and [`06_common_mistakes.md`](06_common_mistakes.md).

---

**Next:** [`03_gene_selection.md`](03_gene_selection.md) — choosing the genes for a panel.
