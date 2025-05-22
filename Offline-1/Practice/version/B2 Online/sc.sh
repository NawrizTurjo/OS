#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# 1. Validate input
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <target_directory>" >&2
    exit 1
fi

target_dir="$1"
if [[ ! -d "$target_dir" ]]; then
    echo "Error: '$target_dir' is not a directory" >&2
    exit 1
fi

# 2. Initialize variables and arrays
total_files=0
duplicates_found=0
space_saved=0
declare -A size_to_files  # Maps size to space-separated list of files
declare -A md5_to_files   # Maps MD5 to space-separated list of files
report_file="Report_1.txt"

# 3. Scan files and group by size
while IFS= read -r -d '' file; do
    # Skip non-regular files or unreadable files
    [[ -f "$file" && -r "$file" ]] || continue

    # Get file size in bytes
    size=$(stat -f %z "$file" 2>/dev/null || stat -c %s "$file" 2>/dev/null)
    if [[ -z "$size" ]]; then
        echo "Warning: Cannot get size for '$file'" >&2
        continue
    fi

    # Increment total files
    ((total_files++))

    # Append file to size group
    size_to_files["$size"]+="${size_to_files["$size"]:+ }$file"
done < <(find "$target_dir" -type f -print0)

# 4. Identify duplicates by MD5 for sizes with multiple files
for size in "${!size_to_files[@]}"; do
    # Split space-separated files into array
    IFS=' ' read -r -a files <<< "${size_to_files[$size]}"

    # Skip if only one file
    if [[ ${#files[@]} -le 1 ]]; then
        continue
    fi

    # Compute MD5 for each file
    declare -A temp_md5_to_files
    for file in "${files[@]}"; do
        md5=$(md5sum "$file" 2>/dev/null | cut -d ' ' -f 1)
        if [[ -z "$md5" ]]; then
            echo "Warning: Cannot compute MD5 for '$file'" >&2
            continue
        fi
        temp_md5_to_files["$md5"]+="${temp_md5_to_files["$md5"]:+ }$file"
    done

    # Process MD5 groups
    for md5 in "${!temp_md5_to_files[@]}"; do
        IFS=' ' read -r -a dupes <<< "${temp_md5_to_files[$md5]}"
        if [[ ${#dupes[@]} -gt 1 ]]; then
            # Keep first file, delete the rest
            for ((i=1; i<${#dupes[@]}; i++)); do
                dupe="${dupes[$i]}"
                if rm -f "$dupe" 2>/dev/null; then
                    ((duplicates_found++))
                    space_saved=$((space_saved + size))
                else
                    echo "Warning: Failed to delete '$dupe'" >&2
                fi
            done
        fi
    done
    unset temp_md5_to_files
done

# 5. Generate report
{
    echo "Total files scanned: $total_files"
    echo "Duplicates found: $duplicates_found"
    # Convert space_saved to MB (1 MB = 1048576 bytes)
    space_mb=$(bc <<< "scale=2; $space_saved / 1048576")
    echo "Space saved: $space_mb MB"
} > "$report_file"

echo "Deduplication complete. Report written to $report_file"