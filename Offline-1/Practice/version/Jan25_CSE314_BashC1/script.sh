#!/usr/bin/env bash
#
# Usage: ./online-StudentID.sh <heist_dir>
#
set -euo pipefail
IFS=$'\n\t'

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <heist_dir>"
  exit 1
fi

root="$1"
blueprints_dir="$root/blueprints"
summary_file="$root/inventory_summary.txt"

# 1. Prepare: remove old outputs
rm -rf "$blueprints_dir"
mkdir -p "$blueprints_dir"
: > "$summary_file"

# 2. Collect counts for even-numbered parts
declare -A counts

# 3. Traverse each city directory
for city_path in "$root"/*; do
  city=$(basename "$city_path")
  # skip non-directories and the blueprints folder itself
  [[ -d "$city_path" && "$city" != "blueprints" ]] || continue

  # 4. For each .dat file in that city...
  for src in "$city_path"/*.dat; do
    [[ -f "$src" ]] || continue
    orig=$(basename "$src")                  # e.g. Part_04_cable.dat
    base="${orig%.*}"                        # Part_04_cable
    ext="${orig##*.}"                        # dat

    # 5. Build new filename: City + space + underscores→spaces
    label="${base//_/ }"                     # "Part 04 cable"
    dest_name="$city $label.$ext"            # "Berlin Part 04 cable.dat"

    # 6. Copy into blueprints/
    cp -- "$src" "$blueprints_dir/$dest_name"

    # 7. If even-numbered part, tally its category
    #    label fields: 1=Part  2=04  3=cable
    part_no=$(awk '{print $2}' <<<"$label")
    if (( 10#$part_no % 2 == 0 )); then
      category=$(awk '{print $3}' <<<"$label")
      counts["$category"]=$((counts["$category"] + 1))
    fi
  done
done

# 8. Write sorted summary
for cat in "${!counts[@]}"; do
  echo "$cat: ${counts[$cat]}"
done | sort >> "$summary_file"

echo "Done. Blueprints in $blueprints_dir; summary in $summary_file."
