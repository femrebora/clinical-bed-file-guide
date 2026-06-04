#!/usr/bin/env bash
#
# make_panel_bed_grch37.sh
#
# Build a targeted gene-panel BED file (exons + 20 bp splice padding, merged)
# from an Ensembl GRCh37 / hg19 reference FASTA.
#
# Usage:
#     bash scripts/make_panel_bed_grch37.sh Homo_sapiens.GRCh37.dna.primary_assembly.fa.gz
#
# The single argument is the path to the reference FASTA (.fa or .fa.gz).
#
# Output (in the current working directory):
#     PANEL.GRCh37.exons.plus20bp.bed   <-- the final file
#
# This script is intentionally verbose and beginner-friendly. It stops at the
# first error (set -e) so you never silently build a broken BED file.

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
GTF_URL="https://ftp.ensembl.org/pub/grch37/release-87/gtf/homo_sapiens/Homo_sapiens.GRCh37.87.gtf.gz"
GTF_FILE="Homo_sapiens.GRCh37.87.gtf.gz"
PADDING=20

# Resolve the directory this script lives in, so it works from anywhere.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

PY_EXTRACT="${SCRIPT_DIR}/extract_gene_exons_from_ensembl_gtf.py"
GENE_LIST="${GENE_LIST:-${REPO_DIR}/data/example_gene_list.txt}"

RAW_BED="PANEL.GRCh37.exons.raw.bed"
SORTED_BED="PANEL.GRCh37.exons.sorted.bed"
PADDED_RAW_BED="PANEL.GRCh37.exons.plus20bp.raw.bed"
FINAL_BED="PANEL.GRCh37.exons.plus20bp.bed"

# ---------------------------------------------------------------------------
# Helper: log a step header
# ---------------------------------------------------------------------------
step() { echo ""; echo ">>> $*"; }

# ---------------------------------------------------------------------------
# 0. Argument check
# ---------------------------------------------------------------------------
if [[ $# -ne 1 ]]; then
    echo "Usage: bash $0 <reference.fa.gz>" >&2
    echo "Example: bash $0 Homo_sapiens.GRCh37.dna.primary_assembly.fa.gz" >&2
    exit 1
fi

REF_INPUT="$1"
if [[ ! -f "${REF_INPUT}" ]]; then
    echo "ERROR: reference file not found: ${REF_INPUT}" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# 1. Check required tools
# ---------------------------------------------------------------------------
step "Step 1/9: Checking required tools (samtools, bedtools, wget, python3)"
missing_tool=0
for tool in samtools bedtools wget python3; do
    if command -v "${tool}" >/dev/null 2>&1; then
        echo "  [ok]      ${tool} -> $(command -v "${tool}")"
    else
        echo "  [MISSING] ${tool}" >&2
        missing_tool=1
    fi
done
if [[ "${missing_tool}" -ne 0 ]]; then
    echo "ERROR: install the missing tools, e.g.:" >&2
    echo "       sudo apt update && sudo apt install samtools bedtools wget python3" >&2
    exit 1
fi

if [[ ! -f "${PY_EXTRACT}" ]]; then
    echo "ERROR: extractor script not found: ${PY_EXTRACT}" >&2
    exit 1
fi
if [[ ! -f "${GENE_LIST}" ]]; then
    echo "ERROR: gene list not found: ${GENE_LIST}" >&2
    exit 1
fi
echo "  Gene list: ${GENE_LIST}"

# ---------------------------------------------------------------------------
# 2. Download the matching Ensembl GRCh37 GTF if missing
# ---------------------------------------------------------------------------
step "Step 2/9: Ensuring Ensembl GRCh37 GTF annotation is present"
if [[ -f "${GTF_FILE}" ]]; then
    echo "  Found existing ${GTF_FILE} (skipping download)."
else
    echo "  Downloading ${GTF_FILE} ..."
    wget -O "${GTF_FILE}" "${GTF_URL}"
fi

# ---------------------------------------------------------------------------
# 3. Uncompress the reference FASTA if needed
# ---------------------------------------------------------------------------
step "Step 3/9: Preparing the reference FASTA"
case "${REF_INPUT}" in
    *.gz)
        REF_FA="${REF_INPUT%.gz}"
        if [[ -f "${REF_FA}" ]]; then
            echo "  Found existing uncompressed FASTA: ${REF_FA}"
        else
            echo "  Decompressing ${REF_INPUT} -> ${REF_FA} (this can take a while)..."
            gunzip -c "${REF_INPUT}" > "${REF_FA}"
        fi
        ;;
    *)
        REF_FA="${REF_INPUT}"
        echo "  Using uncompressed FASTA as-is: ${REF_FA}"
        ;;
esac

# ---------------------------------------------------------------------------
# 4. Index the FASTA with samtools faidx
# ---------------------------------------------------------------------------
step "Step 4/9: Indexing the FASTA with samtools faidx"
if [[ -f "${REF_FA}.fai" ]]; then
    echo "  Found existing index: ${REF_FA}.fai"
else
    samtools faidx "${REF_FA}"
    echo "  Created ${REF_FA}.fai"
fi

# ---------------------------------------------------------------------------
# 5. Create genome.txt (chromosome sizes) from the FASTA index
# ---------------------------------------------------------------------------
step "Step 5/9: Building genome.txt (chromosome sizes) for bedtools slop"
cut -f1,2 "${REF_FA}.fai" > genome.txt
echo "  Wrote genome.txt ($(wc -l < genome.txt) sequences)."

# ---------------------------------------------------------------------------
# 6. Extract panel exons with the Python script
# ---------------------------------------------------------------------------
step "Step 6/9: Extracting exon coordinates for the gene list"
python3 "${PY_EXTRACT}" \
    --gtf "${GTF_FILE}" \
    --genes "${GENE_LIST}" \
    --output "${RAW_BED}"

if [[ ! -s "${RAW_BED}" ]]; then
    echo "ERROR: ${RAW_BED} is empty. Check that gene symbols match the GTF." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# 7. Sort the BED file
# ---------------------------------------------------------------------------
step "Step 7/9: Sorting BED intervals (by chromosome, then start)"
sort -k1,1 -k2,2n "${RAW_BED}" > "${SORTED_BED}"

# ---------------------------------------------------------------------------
# 8. Add 20 bp splice padding with bedtools slop
# ---------------------------------------------------------------------------
step "Step 8/9: Adding ${PADDING} bp splice padding with bedtools slop"
bedtools slop \
    -i "${SORTED_BED}" \
    -g genome.txt \
    -b "${PADDING}" \
    > "${PADDED_RAW_BED}"

# ---------------------------------------------------------------------------
# 9. Merge overlapping intervals with bedtools merge
# ---------------------------------------------------------------------------
step "Step 9/9: Merging overlapping intervals -> ${FINAL_BED}"
sort -k1,1 -k2,2n "${PADDED_RAW_BED}" \
    | bedtools merge -i - -c 4 -o distinct \
    > "${FINAL_BED}"

echo ""
echo "============================================================"
echo "Done. Final BED file: ${FINAL_BED}"
echo "  Intervals: $(wc -l < "${FINAL_BED}")"
echo "  Chromosomes used: $(cut -f1 "${FINAL_BED}" | sort -u | tr '\n' ' ')"
echo ""
echo "Validate it with:"
echo "  bash ${SCRIPT_DIR}/validate_bed_file.sh ${FINAL_BED}"
echo "============================================================"
