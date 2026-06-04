#!/usr/bin/env bash
#
# validate_bed_file.sh
#
# Run basic structural checks on a BED file. This does NOT validate biological
# correctness (genome build, gene choice) — only that the file is a well-formed
# BED with sane coordinates.
#
# Usage:
#     bash scripts/validate_bed_file.sh PANEL.GRCh37.exons.plus20bp.bed
#
# Checks performed:
#   * file exists and is non-empty
#   * start column is numeric
#   * end column is numeric
#   * start < end on every line
#   * start is never negative
#   * prints the chromosome names used
#   * counts total intervals
#   * shows the first 10 lines
#
# Exit status is non-zero if any structural check fails.

set -uo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: bash $0 <file.bed>" >&2
    exit 1
fi

BED="$1"
errors=0

echo "============================================================"
echo "Validating BED file: ${BED}"
echo "============================================================"

# ---------------------------------------------------------------------------
# 1. File exists and is non-empty
# ---------------------------------------------------------------------------
if [[ ! -f "${BED}" ]]; then
    echo "[FAIL] File does not exist: ${BED}" >&2
    exit 1
fi
if [[ ! -s "${BED}" ]]; then
    echo "[FAIL] File is empty: ${BED}" >&2
    exit 1
fi
echo "[ok]   File exists and is non-empty."

# ---------------------------------------------------------------------------
# 2-5. Coordinate checks (skip blank lines and comment/track/browser lines)
# ---------------------------------------------------------------------------
# awk reports the first offending line for each category.
awk -F'\t' '
    /^#/      { next }
    /^track/  { next }
    /^browser/{ next }
    /^[[:space:]]*$/ { next }
    {
        data_lines++
        start = $2
        end   = $3

        if (start !~ /^-?[0-9]+$/) {
            if (!nonnum_start) { print "[FAIL] start not numeric (line " NR "): " $0 > "/dev/stderr"; nonnum_start=1 }
            err=1; next
        }
        if (end !~ /^-?[0-9]+$/) {
            if (!nonnum_end) { print "[FAIL] end not numeric (line " NR "): " $0 > "/dev/stderr"; nonnum_end=1 }
            err=1; next
        }
        if (start+0 < 0) {
            if (!neg_start) { print "[FAIL] negative start (line " NR "): " $0 > "/dev/stderr"; neg_start=1 }
            err=1
        }
        if (start+0 >= end+0) {
            if (!bad_order) { print "[FAIL] start not < end (line " NR "): " $0 > "/dev/stderr"; bad_order=1 }
            err=1
        }
    }
    END {
        if (data_lines == 0) {
            print "[FAIL] no data lines found (only comments/blank?)" > "/dev/stderr"
            exit 2
        }
        if (!nonnum_start) print "[ok]   start column is numeric."
        if (!nonnum_end)   print "[ok]   end column is numeric."
        if (!neg_start)    print "[ok]   start is never negative."
        if (!bad_order)    print "[ok]   start < end on every line."
        exit (err ? 1 : 0)
    }
' "${BED}"
awk_status=$?
if [[ "${awk_status}" -ne 0 ]]; then
    errors=1
fi

# ---------------------------------------------------------------------------
# 6. Chromosome names used
# ---------------------------------------------------------------------------
echo ""
echo "Chromosome names used:"
grep -v -E '^(#|track|browser)' "${BED}" | awk -F'\t' 'NF{print $1}' | sort -u | sed 's/^/  /'

# Friendly hint about naming style.
if grep -v -E '^(#|track|browser)' "${BED}" | awk -F'\t' 'NF{print $1}' | grep -q '^chr'; then
    echo "  (style: UCSC-like, with 'chr' prefix)"
else
    echo "  (style: Ensembl-like, no 'chr' prefix)"
fi

# ---------------------------------------------------------------------------
# 7. Total intervals
# ---------------------------------------------------------------------------
echo ""
total=$(grep -v -E '^(#|track|browser)' "${BED}" | awk -F'\t' 'NF{c++} END{print c+0}')
echo "Total intervals (data lines): ${total}"

# ---------------------------------------------------------------------------
# 8. First 10 lines
# ---------------------------------------------------------------------------
echo ""
echo "First 10 lines:"
head -10 "${BED}" | sed 's/^/  /'

echo ""
echo "============================================================"
if [[ "${errors}" -eq 0 ]]; then
    echo "RESULT: PASS — no structural problems detected."
else
    echo "RESULT: FAIL — see [FAIL] messages above."
fi
echo "============================================================"

exit "${errors}"
