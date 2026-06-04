#!/usr/bin/env python3
"""
extract_gene_exons_from_ensembl_gtf.py

Extract exon coordinates for a list of genes from an Ensembl GTF annotation
file and write them out as a BED6 file.

Key conversion performed here:
    GTF uses 1-based, fully-closed coordinates.
    BED uses 0-based, half-open coordinates.
    Therefore:  bed_start = gtf_start - 1
                bed_end   = gtf_end           (unchanged)

Output columns (BED6, tab-separated):
    chromosome   start   end   gene_name   score   strand

Usage:
    python3 scripts/extract_gene_exons_from_ensembl_gtf.py \\
        --gtf    Homo_sapiens.GRCh37.87.gtf.gz \\
        --genes  data/example_gene_list.txt \\
        --output PANEL.GRCh37.exons.raw.bed

Notes:
  * The GTF may be gzip-compressed (.gz) or plain text; both are handled.
  * Genes are matched on the GTF `gene_name` attribute (HGNC symbol).
  * Chromosome names are taken verbatim from the GTF. An Ensembl GRCh37 GTF
    uses names like 1, 2, ..., X, Y, MT (no "chr" prefix).
"""

import argparse
import gzip
import re
import sys


# Matches:  gene_name "SYMBOL"   inside the GTF attributes column.
GENE_NAME_RE = re.compile(r'gene_name "([^"]+)"')


def open_maybe_gzip(path):
    """Open a file as text, transparently handling gzip-compressed input."""
    if path.endswith(".gz"):
        return gzip.open(path, "rt")
    return open(path, "r")


def load_gene_set(gene_file):
    """Read a gene list (one symbol per line) into a set of symbols."""
    genes = set()
    with open(gene_file) as handle:
        for line in handle:
            gene = line.strip()
            # Skip blank lines and comment lines.
            if not gene or gene.startswith("#"):
                continue
            genes.add(gene)
    if not genes:
        sys.exit(f"ERROR: no gene symbols found in '{gene_file}'.")
    return genes


def extract_exons(gtf_file, genes, out_file):
    """Stream the GTF, write BED6 rows for exons whose gene_name is in `genes`."""
    written = 0
    seen_genes = set()

    with open_maybe_gzip(gtf_file) as gtf, open(out_file, "w") as out:
        for line in gtf:
            if line.startswith("#"):
                continue

            fields = line.rstrip("\n").split("\t")
            if len(fields) != 9:
                continue

            chrom = fields[0]
            feature = fields[2]
            strand = fields[6]
            attrs = fields[8]

            if feature != "exon":
                continue

            match = GENE_NAME_RE.search(attrs)
            if not match:
                continue

            gene_name = match.group(1)
            if gene_name not in genes:
                continue

            # GTF (1-based, closed) -> BED (0-based, half-open)
            gtf_start = int(fields[3])
            gtf_end = int(fields[4])
            bed_start = gtf_start - 1
            bed_end = gtf_end

            out.write(
                f"{chrom}\t{bed_start}\t{bed_end}\t{gene_name}\t0\t{strand}\n"
            )
            written += 1
            seen_genes.add(gene_name)

    return written, seen_genes


def main():
    parser = argparse.ArgumentParser(
        description="Extract exon BED6 records for a gene list from an Ensembl GTF."
    )
    parser.add_argument(
        "--gtf",
        required=True,
        help="Path to the Ensembl GTF file (.gtf or .gtf.gz).",
    )
    parser.add_argument(
        "--genes",
        required=True,
        help="Path to a gene list file (one HGNC symbol per line).",
    )
    parser.add_argument(
        "--output",
        required=True,
        help="Path to the output BED6 file.",
    )
    args = parser.parse_args()

    genes = load_gene_set(args.genes)
    written, seen_genes = extract_exons(args.gtf, genes, args.output)

    # Report a short summary to stderr so it does not pollute the BED output.
    missing = sorted(genes - seen_genes)
    print(f"Wrote {written} exon records to '{args.output}'.", file=sys.stderr)
    print(f"Genes requested : {len(genes)}", file=sys.stderr)
    print(f"Genes found     : {len(seen_genes)}", file=sys.stderr)
    if missing:
        print(
            "WARNING: no exons found for these genes (check the symbol / GTF): "
            + ", ".join(missing),
            file=sys.stderr,
        )


if __name__ == "__main__":
    main()
