#!/usr/bin/env bash
#
# Usage: ./categorize_photos.sh <input_dir> <photos_dir>
#
# Moves JPEGs from the input directory into photos_dir/{morning,afternoon,evening}
# based on the HH from IMG_YYYYMMDD_HHMMSS.jpg, then updates photos_dir/counts.txt.

set -euo pipefail
IFS=$'\n\t'

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <input_dir> <photos_dir>"
  exit 1
fi

input_dir="$1"
photos_dir="$2"
counts_file="$photos_dir/counts.txt"

# 1. Make sure the target subfolders exist
for period in morning afternoon evening; do
  mkdir -p "$photos_dir/$period"
done

# 2. Loop over each JPG in the input dir
find "$input_dir" -maxdepth 1 -type f -iname 'IMG_*.jpg' -print0 |
while IFS= read -r -d '' img; do
  base="$(basename "$img")"
  name="${base%.*}"             # strip extension: IMG_20250501_001113
  time_part="${name##*_}"       # grab after last _: 001113
  hour="${time_part:0:2}"       # first two digits: 00

  # 3. Decide morning|afternoon|evening
  if (( 10#$hour < 12 )); then
    period="morning"
  elif (( 10#$hour < 17 )); then
    period="afternoon"
  else
    period="evening"
  fi

  # 4. Move it
  mv -- "$img" "$photos_dir/$period/"
done

# 5. Rebuild counts.txt
{
  for period in morning afternoon evening; do
    cnt=$(find "$photos_dir/$period" -maxdepth 1 -type f | wc -l)
    echo "$period $cnt"
  done
} > "$counts_file"

echo "Done: photos sorted and counts.txt updated."
