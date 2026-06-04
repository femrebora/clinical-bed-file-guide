# Useful databases & references

A curated list of resources for **gene selection**, **genomic coordinates**, and **BED/tooling documentation**. Always prefer the current, authoritative version of each resource for clinical work.

---

## Gene selection & clinical evidence

### ClinGen
Gene–disease validity curation and clinical evidence, organized by disease-specific expert panels. Find the panel relevant to your condition and review the gene-validity classifications.
- https://clinicalgenome.org/
- Curation activities / expert panels: https://clinicalgenome.org/curation-activities/

### GeneReviews
Peer-reviewed clinical summaries: inheritance patterns, phenotypes, and core genes for many conditions.
- https://www.ncbi.nlm.nih.gov/books/NBK1116/

### Genomics England PanelApp
Crowd-sourced, expert-reviewed **gene panels** with green/amber/red evidence ratings. Search for the panel relevant to your condition.
- https://panelapp.genomicsengland.co.uk/

### OMIM (Online Mendelian Inheritance in Man)
Catalog of human genes and genetic disorders; useful for disease–gene relationships and disease subtype naming.
- https://www.omim.org/

### HGNC (HUGO Gene Nomenclature Committee)
The authority for **official gene symbols**. Use it to confirm the exact symbol (and avoid aliases) before matching against a GTF.
- https://www.genenames.org/

### ClinVar
Public archive of reported variants and their clinical significance. Use it **after** selecting genes to review known variants.
- https://www.ncbi.nlm.nih.gov/clinvar/

---

## Genomic coordinates & annotation

### Ensembl GRCh37 (hg19)
The GRCh37 genome browser and download site. Source of the reference FASTA and the GTF annotation used in this guide.
- Browser: https://grch37.ensembl.org/
- GTF (release-87): https://ftp.ensembl.org/pub/grch37/release-87/gtf/homo_sapiens/Homo_sapiens.GRCh37.87.gtf.gz
- FASTA directory: https://ftp.ensembl.org/pub/grch37/release-87/fasta/homo_sapiens/dna/

---

## Format & tooling documentation

### UCSC BED format FAQ
The canonical description of the BED format, columns, and the 0-based half-open convention.
- https://genome.ucsc.edu/FAQ/FAQformat.html#format1

### bedtools documentation
Documentation for `bedtools` (including `slop`, `merge`, `sort`, `intersect`) used to pad and merge intervals.
- https://bedtools.readthedocs.io/

### samtools documentation
Documentation for `samtools` (including `faidx`) used to index the reference FASTA and produce the `.fai` chromosome-size file.
- http://www.htslib.org/doc/samtools.html

---

## How these fit together

| Stage | Resource(s) |
|-------|-------------|
| Decide **which genes** | ClinGen, GeneReviews, PanelApp, OMIM |
| Confirm **gene symbols** | HGNC |
| Review **known variants** | ClinVar |
| Get **exon coordinates** | Ensembl GRCh37 (FASTA + GTF) |
| Understand **BED format** | UCSC BED FAQ |
| **Build/pad/merge** intervals | bedtools, samtools |
