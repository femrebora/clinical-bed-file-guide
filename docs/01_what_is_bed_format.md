# 01 — What is a BED file?

A **BED file** (Browser Extensible Data) is a plain-text, tab-separated file that lists **genomic regions**. Each line describes one region with, at minimum, a chromosome and a start/end position.

BED files are everywhere in genomics: they define the **target regions** of a sequencing panel, they tell tools which regions to **keep or analyze**, and they drive **coverage** reports.

---

## The columns

BED columns are **positional** and **tab-separated**. The first three are mandatory; the rest are optional but must appear in order.

| # | Column        | Required? | Meaning                                              |
|---|---------------|-----------|------------------------------------------------------|
| 1 | `chrom`       | yes       | Chromosome name (e.g. `7`, or `chr7` in UCSC style). |
| 2 | `chromStart`  | yes       | **0-based** start position.                          |
| 3 | `chromEnd`    | yes       | **Half-open** end position (1 past the last base).   |
| 4 | `name`        | no        | Region name — often a gene symbol.                   |
| 5 | `score`       | no        | 0–1000 score (often unused; set to `0`).             |
| 6 | `strand`      | no        | `+`, `-`, or `.`                                     |

### BED3, BED4, BED6

The number tells you how many columns are used:

- **BED3** — `chrom  start  end`. The bare minimum: just regions.
  ```
  7	44183849	44186002
  ```
- **BED4** — adds a **name** column (commonly the gene). *Many clinical kit target BEDs are BED4.*
  ```
  7	44183849	44186002	GCK
  ```
- **BED6** — adds **score** and **strand**.
  ```
  7	44183849	44186002	GCK	0	+
  ```

> The Python extractor in this repo outputs **BED6**. The final merged file is effectively **BED4** (chrom, start, end, gene name) because merging collapses strand/score.

---

## The part everyone gets wrong: 0-based, half-open

BED uses a coordinate system that differs from how humans usually write positions. Two rules:

1. **0-based start** — counting starts at `0`, not `1`.
2. **Half-open interval** — the **end** position is **not included**; it is one past the last base.

Think of the coordinates as sitting **between** the bases (like a ruler), not on them:

```
 position markers:  0   1   2   3   4   5
 bases:               A   C   G   T   A
                    ^                   ^
                  start=0            end=5   -> covers ACGTA (5 bases)
```

So the **length** of a BED interval is simply `end - start`.

### Worked examples

| Human-readable (1-based) | BED (0-based, half-open) | Length |
|--------------------------|--------------------------|--------|
| `chr8:100001-100500`     | `8  100000  100500`      | 500 bp |
| Single base `8:3254`     | `8  3253  3254`          | 1 bp   |
| First base of a chrom    | `8  0  1`                | 1 bp   |

The conversion rule:

```
BED start = (1-based start) - 1
BED end   = (1-based end)         # unchanged
```

This is exactly why the extraction script subtracts 1 from the GTF start (GTF is 1-based) but leaves the end alone. See [`04_create_panel_bed_grch37.md`](04_create_panel_bed_grch37.md).

---

## Why 0-based, half-open? (it's not arbitrary)

This convention makes arithmetic clean:

- **Length** = `end - start` (no `+1` needed).
- **Adjacent regions** meet exactly: `[0,5)` and `[5,10)` touch with no gap and no overlap.
- **Empty region** is naturally `start == end` (zero length).

Compare with 1-based, fully-closed systems (used by GTF, GFF, VCF, SAM, and most genome browsers' display), where length is `end - start + 1` and adjacency is fiddly. BED chose the programmer-friendly convention; GTF/VCF chose the human-friendly one. **Mixing them up by one base is one of the most common bioinformatics bugs** — see [`06_common_mistakes.md`](06_common_mistakes.md).

---

## A note on chromosome naming

The same chromosome can be written two ways:

| Style    | Examples                          | Used by                                   |
|----------|-----------------------------------|-------------------------------------------|
| Ensembl  | `1`, `2`, `X`, `Y`, `MT`          | Ensembl references & GTFs (incl. GRCh37)  |
| UCSC     | `chr1`, `chr2`, `chrX`, `chrM`    | UCSC genome browser, many older pipelines |

Your BED file's naming **must match** the reference/BAM/VCF you use it with. This guide uses **Ensembl style** throughout, because the reference is `Homo_sapiens.GRCh37.dna.primary_assembly.fa.gz`. More on this in [`06_common_mistakes.md`](06_common_mistakes.md).

---

**Next:** [`02_understanding_clinical_target_bed.md`](02_understanding_clinical_target_bed.md) — how to read a real clinical target BED.
