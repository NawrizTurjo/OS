# #!/bin/bash

# # Declare associative array to store Artist -> Titles mapping
# declare -A catalog

# # Scan media/ directory for .mp3, .flac, .mp4, .mkv files
# while IFS= read -r file; do
#   # Get filename without path and extension
#   filename=$(basename "$file")
#   # echo "$filename"
#   name_no_ext="${filename%.*}"
#   echo "Raw Name: $name_no_ext"

#   # Initialize Artist and Title as Unknown
#   artist="Unknown"
#   title="Unknown"

#   # Pattern 1: Artist - Title
#   if [[ $name_no_ext =~ ^(.+)[[:space:]]\([0-9]{4}\)[[:space:]]-[[:space:]](.+)$ ]]; then
#     artist="${BASH_REMATCH[2]}"
#     title="${BASH_REMATCH[1]}"
#     # echo "Pattern 1 matched"
#   # Pattern 2: Title (Year) - Artist
#   elif [[ $name_no_ext =~ ^(.+)[[:space:]]-[[:space:]](.+)$ ]]; then
#     title="${BASH_REMATCH[2]}"
#     artist="${BASH_REMATCH[1]}"
#     # echo "Pattern 2 matched"
#   fi
#   # echo "Extracted artist name: $artist"
#   # echo "Extracted title name: $title"
#   # echo " "

#   # Append Title to Artist's list in the catalog
#   if [ -n "$artist" ] && [ -n "$title" ]; then
#     catalog["$artist"]="${catalog["$artist"]} $title"
#   fi
# done < <(find media/ -type f \( -name "*.mp3" -o -name "*.flac" -o -name "*.mp4" -o -name "*.mkv" \))

# # Debug: Print the entire catalog array
# # echo "Debug: Contents of catalog array:"
# # for artist in "${!catalog[@]}" ; do
# #   echo "Artist: $artist, Titles: ${catalog[$artist]}"
# # done
# # echo " "

# # # Generate catalog_1.txt
# # : > catalog_1.txt  # Clear or create catalog_1.txt

# # # Sort artists alphabetically and write to catalog_1.txt
# for artist in "${!catalog[@]}" ; do
#   echo "$artist"
# #   # Split titles, sort them, and print
#   IFS=' ' read -r -a titles <<< "${catalog[$artist]}"
#   for title in "${titles[@]}" ; do
#     echo "$title"
#   done | sort
# done | sort


#!/bin/bash

# Check if correct number of arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <media_directory> <output_file>"
    exit 1
fi

media_dir="$1"
output_file="$2"

# Check if media directory exists
if [ ! -d "$media_dir" ]; then
    echo "Error: Media directory '$media_dir' does not exist."
    exit 1
fi

declare -A artist_map  # Associative array to store artist-title mappings

# Process each media file in the directory
while IFS= read -r file; do
    filename=$(basename "$file")
    artist="Unknown"
    title="Unknown"

    # Check for "Artist - Title" pattern
    if [[ "$filename" =~ ^([^-]+)\ -\ (.+)\.(mp3|flac|mp4|mkv)$ ]]; then
        artist=$(echo "${BASH_REMATCH[1]}" | xargs)  # Trim whitespace
        title=$(echo "${BASH_REMATCH[2]}" | xargs)
    # Check for "Title (Year) - Artist" pattern
    elif [[ "$filename" =~ ^(.+)\ \([0-9]{4}\)\ -\ (.+)\.(mp3|flac|mp4|mkv)$ ]]; then
        title=$(echo "${BASH_REMATCH[1]}" | xargs)
        artist=$(echo "${BASH_REMATCH[2]}" | xargs)
    fi

    # Add to associative array
    artist_map["$artist"]+="$title"$'\n'
done < <(find "$media_dir" -type f \( -name "*.mp3" -o -name "*.flac" -o -name "*.mp4" -o -name "*.mkv" \))

# Generate the catalog file
{
    # Sort artists alphabetically
    for artist in $(printf '%s\n' "${!artist_map[@]}" | sort); do
        echo "$artist"
        # Sort titles alphabetically for each artist
        printf '%s' "${artist_map[$artist]}" | sort | while read -r title; do
            [ -n "$title" ] && echo "  $title"
        done
    done
} > "$output_file"

echo "Catalog generated successfully at $output_file"