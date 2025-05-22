#!/usr/bin/bash

target_dir=$1

# echo "${DIR}"

# cp -r "$DIR" target_dir

declare -A sizemap

duplicates_found=0
space_saved=0

initial_file_count=$(find "${target_dir}" -type f | wc -l)

while read -r filename; do
    
    file_size=$(ls -la "$filename" | awk '{print $5}')
    # echo "$file_size"

    if [[ -v "${sizemap[$file_size]}" ]]; then 
        sizemap["$file_size"]=$filename
    else
        sizemap["$file_size"]+=$'\n'"$filename"
    fi

done < <(find "${target_dir}" -type f)

# echo ${!sizemap[@]}
# echo ${sizemap[@]}

while read -r file_size; do
    declare -A md5_sum
    # echo $file_size
    # echo "${sizemap["$file_size"]}"

    for file_name in ${sizemap["$file_size"]}
    do
        # echo $file_name
        hashvar=$(md5sum "$file_name" | cut -d ' ' -f 1)
        # echo  $file_name
        if [[ -z ${md5_sum["$hashvar"]} ]]; then
            md5_sum["$hashvar"]=abc
        else
            space_saved=$(( space_saved + file_size ))
            (( duplicates_found++ ))
            # rm -r "$file_name"
            echo "$file_name"
        fi

    done



done < <(printf "%s\n" "${!sizemap[@]}")

{
    echo "Total files scanned: ${initial_file_count}"
    echo "Duplicates found: ${duplicates_found}"
    echo "Space saved: ${space_saved} bytes"
}> "info.txt"

# for size_grp in ${sizemap[@]}
# do
#     echo "$size_grp"
# done