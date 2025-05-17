#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t' # IFS means "Internal Field Separator" and is used to split input into words

# Recursively find every .txt under this directory
find . -type f -iname '*.txt' | while read -r file; do
  # Read only the non-blank lines into an array
  mapfile -t lines < <(grep -v '^[[:space:]]*$' "$file")

  # lines[0] = Player Name
  country="${lines[1]:-}"
  role="${lines[2]:-}"

  printf 'File: %s\n' "$file"
  printf '  Country: %s\n' "$country"
  printf '  Role:    %s\n\n' "$role"

  mkdir -p "$country/$role"
  # avoid overwriting existing files
    if [[ -e "$country/$role/${file##*/}" ]]; then
        echo "File already exists: $country/$role/${file##*/}"
        continue
    fi
  cp -- "$file" "$country/$role/"
done
