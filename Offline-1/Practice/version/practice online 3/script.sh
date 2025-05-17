#!/usr/bin/env bash
#
# Usage: ./filter_and_rename_pdfs.sh <min_pages>
#
# Recursively finds all PDFs under the current directory,
# copies those with more than <min_pages> pages into ./filtered_pdfs/,
# then renames them 1.pdf, 2.pdf … in ascending file-size order.

rm -d filtered_pdfs 2>/dev/null || true

set -euo pipefail
IFS=$'\n\t'

# 1) Check arguments
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <min_pages>"
  exit 1
fi
min_pages=$1

# 2) Ensure pdfinfo is installed (part of poppler-utils)
if ! command -v pdfinfo &> /dev/null; then
  echo "Error: 'pdfinfo' not found. Install poppler-utils."
  echo " Run: sudo apt install poppler-utils"
  exit 1
fi

outdir="filtered_pdfs"
mkdir -p "$outdir"

echo "→ Scanning for PDFs with more than $min_pages pages…"

# 3) Find & copy
while IFS= read -r -d '' pdf; do
  # get page count
  pages=$(pdfinfo "$pdf" 2>/dev/null | awk '/^Pages:/ {print $2}')
  if [[ -n "$pages" && "$pages" -gt "$min_pages" ]]; then
    cp -- "$pdf" "$outdir/"
  fi
done < <(find . -type f -iname '*.pdf' -print0)

echo "→ Copied to $outdir. Now renaming by file size…"

# 4) Rename them 1.pdf, 2.pdf … in size order
cd "$outdir"
# build a sorted list: "<size><TAB><filename>"
mapfile -t sorted < <(find . -maxdepth 1 -type f -iname '*.pdf' \
    -printf '%s\t%f\n' | sort -n | cut -f2)

i=1
for f in "${sorted[@]}"; do
  mv -- "$f" "${i}.pdf"
  ((i++))
done

count=$((i - 1))
echo "✔ Done: $count files → 1.pdf through ${count}.pdf"
