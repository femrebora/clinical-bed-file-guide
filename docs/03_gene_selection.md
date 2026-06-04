# 03 — Gene selection for a targeted panel

Building a panel BED file starts with one question: **which genes belong on the panel?** This page explains where to look and how to decide, independent of any specific disease.

> Gene selection is a **clinical/scientific** decision, not just a technical one. The example genes used elsewhere in this repo are arbitrary placeholders — always build your own list from authoritative, up-to-date sources.

---

## Where gene names and evidence come from

Different databases serve different purposes. Some tell you **which genes are clinically valid** for a condition; one tells you **where the exons are**.

| Resource | Best used for | Role in this workflow |
|----------|---------------|------------------------|
| **ClinGen** | Gene–disease **validity** & evidence strength, curated by disease-specific expert panels. | **Gene selection** |
| **GeneReviews** | Clinical summaries: inheritance patterns, phenotypes, and core genes per condition. | **Gene selection** |
| **Genomics England PanelApp** | Expert-reviewed **gene panels** with green/amber/red evidence ratings. | **Gene selection** |
| **OMIM** | Disease–gene relationships and disease subtype naming. | **Gene selection / cross-check** |
| **HGNC** | Official, current **gene symbols** (avoid aliases). | **Symbol confirmation** |
| **ClinVar** | Reported variants and their clinical classifications. | **Post-selection variant context** |
| **Ensembl GRCh37** | Gene/transcript/**exon coordinates** and the GTF annotation. | **Genomic coordinates** |

**Key distinction:**

- **ClinGen, GeneReviews, and PanelApp** are the better sources for deciding **which genes are clinically relevant**.
- **Ensembl** is used afterwards to get the **genomic coordinates** (exons) for the genes you chose.
- **HGNC** ensures the symbol you put in your gene list matches the symbol in the GTF (mismatched aliases = missing exons).

Links for all of these are in [`../references/useful_databases.md`](../references/useful_databases.md).

---

## Recommended approach

1. **Draft** a gene list from disease-specific sources (ClinGen + GeneReviews + PanelApp).
2. **Cross-check** subtypes and disease relationships in OMIM.
3. **Normalize** every symbol against HGNC (use the official symbol, not an alias).
4. Only then, **map to coordinates** with the Ensembl GRCh37 GTF.

> For clinical use, **do not rely on a single source**. Compare ClinGen, GeneReviews, PanelApp, OMIM, and HGNC before finalizing — and consider the evidence level of each gene, not just its presence on some list.

---

## The example gene list in this repo

The file [`../data/example_gene_list.txt`](../data/example_gene_list.txt) contains a handful of **arbitrary, widely-known public genes** used only to demonstrate the pipeline end to end:

```
TP53
BRCA1
BRCA2
CFTR
EGFR
```

These are **not** a curated clinical panel and carry no clinical meaning here — they are simply well-annotated genes that let the build script produce real output. **Replace them with your own list.**

### Using your own list

Create a plain-text file, one official HGNC symbol per line, and pass it to the build script via the `GENE_LIST` variable:

```bash
printf 'GENE1\nGENE2\nGENE3\n' > data/my_panel_genes.txt
GENE_LIST=data/my_panel_genes.txt \
  bash scripts/make_panel_bed_grch37.sh Homo_sapiens.GRCh37.dna.primary_assembly.fa.gz
```

---

**Next:** [`04_create_panel_bed_grch37.md`](04_create_panel_bed_grch37.md) — build the BED file step by step.
