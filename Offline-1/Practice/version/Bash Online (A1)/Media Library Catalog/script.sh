#!/usr/bin/env bash
#
# Usage: ./script.sh <media_dir> <output_file>
#
shopt -s nullglob
declare -A catalog

media_dir="$1"
out_file="$2"

# 1. Collect all media files
while IFS= read -r -d '' file; do
  base=$(basename "$file")
  name="${base%.*}"

  # 2a. Pattern: Artist - Title.ext
  if [[ $name =~ ^(.+)[[:space:]]-[[:space:]](.+)$ ]]; then
    artist="${BASH_REMATCH[1]}"
    title="${BASH_REMATCH[2]}"

  # 2b. Pattern: Title (Year) - Artist.ext
  elif [[ $name =~ ^(.+)[[:space:]]\([0-9]{4}\)[[:space:]]-[[:space:]](.+)$ ]]; then
    title="${BASH_REMATCH[1]}"
    artist="${BASH_REMATCH[2]}"

  # 2c. Fallback
  else
    artist="Unknown"
    title="Unknown"
  fi

  # 3. Append title to artist’s list (newline-separated)
  catalog["$artist"]+="${title}"$'\n'

done < <(find "$media_dir" -maxdepth 1 -type f \
            \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.mp4" -o -iname "*.mkv" \) \
            -print0)

# 4. Write out sorted catalog
: > "$out_file"   # truncate/create

# sort artists
for artist in $(printf '%s\n' "${!catalog[@]}" | sort); do
  echo "$artist" >> "$out_file"
  # sort and print titles under each artist
  printf '%s\n' "${catalog["$artist"]}" |
    sort |
    while IFS= read -r title; do
      echo "$title" >> "$out_file"
    done
  echo >> "$out_file"   # blank line between artists
done
