# 06 — Common mistakes (and how to avoid them)

Most BED problems are silent: the tools run without error but produce **wrong results**. Here are the traps, why they happen, and how to catch them.

---

## 1. Using GRCh38 coordinates with a GRCh37 reference (wrong build)

**Symptom:** Regions point to the wrong place; variants fall outside exons; coverage looks bizarre.

**Why:** GRCh37 (hg19) and GRCh38 (hg38) have **different coordinates** for the same gene. A BED built from a GRCh38 GTF is meaningless against a GRCh37 reference, and vice versa.

**Avoid it:**
- Build the BED from the **same build** as your reference and your BAM/VCF.
- This guide pairs `Homo_sapiens.GRCh37.dna.primary_assembly.fa.gz` with `Homo_sapiens.GRCh37.87.gtf.gz` — both GRCh37.
- If you must move between builds, **lift over** (e.g. UCSC liftOver / CrossMap) — never just relabel.

---

## 2. Using `chr1` when the reference uses `1` (naming mismatch)

**Symptom:** Tools report **zero** overlapping regions, or "chromosome not found." No error, just empty output.

**Why:** `chr1` (UCSC) and `1` (Ensembl) are different strings. Tools match chromosome names **literally**.

**Avoid it:**
```bash
cut -f1 your.bed | sort -u     # must match the reference/BAM/VCF naming
```
Keep Ensembl style (`1, 2, X, Y, MT`) with the Ensembl GRCh37 reference. Convert only if your BAM/VCF genuinely uses `chr` (see the conversion snippet in [`04_create_panel_bed_grch37.md`](04_create_panel_bed_grch37.md)).

---

## 3. Forgetting to subtract 1 from the GTF start (off-by-one)

**Symptom:** Every interval is shifted by one base; edge variants are gained/lost.

**Why:** **GTF is 1-based, closed**; **BED is 0-based, half-open**. The start must be decremented:
```
bed_start = gtf_start - 1
bed_end   = gtf_end          # unchanged
```

**Avoid it:** Use the provided extractor — it does this conversion for you. If you hand-roll one, never forget the `- 1` on the **start only**. See [`01_what_is_bed_format.md`](01_what_is_bed_format.md).

---

## 4. Using whole-gene intervals instead of exons

**Symptom:** Huge intervals spanning entire genes (introns included); enormous, noisy target regions.

**Why:** Extracting `gene` features (or transcript spans) instead of `exon` features. For a targeted panel you almost always want **exons**, not the full gene body.

**Avoid it:** Filter on `feature == "exon"` (the extractor does this). Only use gene-level spans if you specifically intend to include introns.

---

## 5. Not adding splice padding

**Symptom:** Pathogenic **splice-site** variants just outside the coding exon are missed.

**Why:** Coding exon boundaries don't include the canonical splice sites a few bases into the intron.

**Avoid it:** Add padding (this guide uses **20 bp** per side via `bedtools slop`). Choose a padding appropriate to your application and document it.

---

## 6. Not sorting the BED file

**Symptom:** `bedtools merge` produces wrong or partial results; "input is not sorted" errors.

**Why:** `merge` (and many bedtools ops) assume input sorted by chromosome then start.

**Avoid it:**
```bash
sort -k1,1 -k2,2n in.bed > out.sorted.bed
```
Always sort **before** merging. Verify with `sort -c -k1,1 -k2,2n file.bed`.

---

## 7. Using a clinical kit BED built for a different genome build

**Symptom:** A manufacturer BED appears valid but maps to the wrong locations.

**Why:** Kit BEDs are build-specific. A `hg19` kit BED used against a GRCh38 analysis (or vice versa) is silently wrong.

**Avoid it:** Confirm the **build** stated by the manufacturer and match it to your pipeline. Don't assume; check the documentation that ships with the kit.

---

## 8. Assuming a gene-based BED equals a manufacturer target BED

**Symptom:** Coverage QC disagrees with the lab; some "covered" regions have no reads.

**Why:** A gene-based exon BED is a **model** of what *should* be covered. A manufacturer target BED reflects the **actual** probe/amplicon design — which may not cover every exon equally (especially amplicon kits).

**Avoid it:**
- Use the **gene-based BED** for variant filtering, annotation, and approximate region analysis.
- Use the **manufacturer target BED** for true coverage analysis and clinical reporting.
- See the clinical note in the [README](../README.md) and [`02_understanding_clinical_target_bed.md`](02_understanding_clinical_target_bed.md).

---

## Quick triage table

| You see… | Likely cause | First check |
|----------|--------------|-------------|
| Zero overlaps / empty output | Naming or build mismatch | `cut -f1 file.bed \| sort -u`; confirm build |
| Everything shifted 1 bp | Missing `-1` on GTF start | Re-extract with the provided script |
| Giant intervals | Used `gene` not `exon` | Confirm `feature == "exon"` |
| Splice variants missing | No padding | Re-run `bedtools slop -b 20` |
| `merge` errors / odd output | Unsorted input | `sort -k1,1 -k2,2n` first |
| Coverage disagrees with lab | Gene BED ≠ kit BED | Use the manufacturer target BED for QC |

---

**Back to:** [README](../README.md) · [`05_validate_bed_files.md`](05_validate_bed_files.md)
