#!/usr/bin/bash

DIR="$1"

echo -n "" > "$2"

path=.some_temp_dir
mkdir -p "$path"

find "$DIR" -type f -name "*.mp3" -o -name "*.flac" -o -name "*.mp4" -o -name "*.mkv" > temp_file_list.txt

declare -A artist_map

for word in $(cat temp_file_list.txt); do
    # echo "$word"
    echo -n ""
done


IFS=$'\n'
for line in $(cat temp_file_list.txt); do
    # echo "$line"
    echo -n ""
done

# unset IFS
unset IFS



while read -r file; do
    file=${file##*\/}
    # file=${file%.*}
    artist="Unknown"
    title="Unknown"
    if [[ "$file" =~ ^([^-\(]+)\ -\ (.+)\.(mp3|flac|mp4|mkv)$ ]]; then
        artist="${BASH_REMATCH[1]}"
        title="${BASH_REMATCH[2]}"
    elif [[ "$file" =~ ^(.+)\ \([0-9]{4}\)\ -\ (.+)\.(mp3|flac|mp4|mkv)$ ]]; then
        artist="${BASH_REMATCH[2]}"
        title="${BASH_REMATCH[1]}"
    fi

    # echo ARTIST = "$artist" TITLE = "$title" >> "$2"

    if [[ "$artist" != "Unknown" && "$title" != "Unknown" ]]; then
        if [[ -z "${artist_map[$artist]}" ]]; then
            artist_map["$artist"]="$path/$artist.txt"
            echo -n "" > "${artist_map[$artist]}"
        fi
        echo "$title" >> "${artist_map[$artist]}"
    fi
    
done < temp_file_list.txt


# awk -F '__' '{print $2}' sample.txt
# cut -d '.t' -f3 sample.txt | cut -d '_' -f1 | cut -c 2-3

# for artist in "${!artist_map[@]}"; do
#     echo "$artist"
# done > tasty.trt

# for artist in $(cat tasty.trt); do
#     echo "$artist"
# done

# printf "%s\n" "${!artist_map[@]}" | sort > tasty.trt


# echo -n "" > "$path/artist_list.txt"
# for artist in "${!artist_map[@]}"; do
#     echo "$artist" >> "$path/artist_list.txt"
# done


# while read -r artist; do
#     echo "$artist" >> "$2"
#     artist_file="${artist_map[$artist]}"

#     while read -r title; do
#         echo "    $title" >> "$2"
#     done < <(sort "$artist_file")

# done < <(sort "$path/artist_list.txt")

IFS=$'\n'
for artist in $(printf "%s\n" "${!artist_map[@]}" | sort); do
    artist_file="${artist_map[$artist]}"
    echo "$artist" >> "$2"
    while read -r title; do
        echo "    $title" >> "$2"
    done < <(sort "$artist_file")
done

rm -rf "$path"
rm temp_file_list.txt