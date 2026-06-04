# 05 — Validating BED files

A BED file can be **structurally** valid (well-formed columns and coordinates) yet **biologically** wrong (wrong genome build, wrong naming). Always check both. The helper script covers the structural part:

```bash
bash scripts/validate_bed_file.sh PANEL.GRCh37.exons.plus20bp.bed
```

Below are the individual checks, so you understand what "valid" means and can run them by hand.

---

## 1. Preview the file — `head`

```bash
head PANEL.GRCh37.exons.plus20bp.bed
```

Confirms columns, naming style, and that there is real data (not an empty or HTML error page from a failed download).

## 2. Count intervals — `wc -l`

```bash
wc -l PANEL.GRCh37.exons.plus20bp.bed
```

A plausible count for a small panel is dozens to a few hundred merged intervals. **Zero or one** line usually means something failed upstream (e.g. no gene matched).

## 3. Coordinate sanity — `awk`

The single most useful check. It should print **nothing**:

```bash
# Flag any interval with negative start or end <= start
awk -F'\t' '$2 < 0 || $3 <= $2' PANEL.GRCh37.exons.plus20bp.bed
```

Confirm start/end are numeric:

```bash
awk -F'\t' '$2 !~ /^[0-9]+$/ || $3 !~ /^[0-9]+$/ {print "non-numeric:", $0}' \
    PANEL.GRCh37.exons.plus20bp.bed
```

## 4. Chromosome-naming check

```bash
cut -f1 PANEL.GRCh37.exons.plus20bp.bed | sort -u
```

For an Ensembl GRCh37 reference you expect:

```
2
7
11
12
13
17
20
...
```

You should **not** see `chr2`, `chr7`, … unless you deliberately converted to UCSC naming. Mismatched naming is the #1 cause of "my BED matches zero regions." See [`06_common_mistakes.md`](06_common_mistakes.md).

## 5. Sorting check

`bedtools merge` requires sorted input. Verify it is sorted:

```bash
# Prints nothing if already sorted by chrom then start:
sort -c -k1,1 -k2,2n PANEL.GRCh37.exons.plus20bp.bed && echo "sorted OK"
```

If not sorted:

```bash
sort -k1,1 -k2,2n file.bed > file.sorted.bed
```

## 6. Overlap / merge check

After merging, no two intervals on the same chromosome should overlap. A quick way to confirm merging actually collapsed overlaps is to re-run merge and compare counts:

```bash
before=$(wc -l < PANEL.GRCh37.exons.plus20bp.bed)
after=$(sort -k1,1 -k2,2n PANEL.GRCh37.exons.plus20bp.bed | bedtools merge -i - | wc -l)
echo "intervals: ${before}  |  after re-merge: ${after}"
```

If `after` is **smaller** than `before`, the file still contained overlaps and was not fully merged.

## 7. Compatibility with the FASTA index

Every chromosome in your BED must exist in the reference index, and no interval may exceed the chromosome length. Compare against `genome.txt` (built from the `.fai`):

```bash
# Chromosomes in the BED that are NOT present in the reference index:
comm -23 \
  <(cut -f1 PANEL.GRCh37.exons.plus20bp.bed | sort -u) \
  <(cut -f1 genome.txt | sort -u)
```

Nothing printed = every BED chromosome exists in the reference. (Because the pipeline uses `bedtools slop -g genome.txt`, padded intervals are already clamped to chromosome lengths.)

---

## Validation checklist

| ✔ | Check | Command |
|---|-------|---------|
| ☐ | File previews correctly | `head file.bed` |
| ☐ | Reasonable interval count | `wc -l file.bed` |
| ☐ | No broken coordinates | `awk -F'\t' '$2<0 \|\| $3<=$2' file.bed` |
| ☐ | start/end numeric | `awk -F'\t' '$2!~/^[0-9]+$/\|\|$3!~/^[0-9]+$/' file.bed` |
| ☐ | Naming matches reference | `cut -f1 file.bed \| sort -u` |
| ☐ | Sorted | `sort -c -k1,1 -k2,2n file.bed` |
| ☐ | Fully merged (no overlaps) | re-merge & compare counts |
| ☐ | Chromosomes exist in reference | `comm -23` against `genome.txt` |

If all pass, the file is **structurally** sound. Biological correctness (right build, right genes, right transcripts) still depends on your inputs — see [`06_common_mistakes.md`](06_common_mistakes.md).

---

**Next:** [`06_common_mistakes.md`](06_common_mistakes.md) — the traps that silently corrupt results.
