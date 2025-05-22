
base_dir="heist"

mkdir -p "Blueprints_final/blueprints"

dir="Blueprints_final"

blu_dir="blueprints"

txtfile="inventory_report.txt"

declare -A count_map


for city in "${base_dir}"/*;
do
    city_name=$(basename ${city})
    # echo "$city_name"
    # echo "$city_name"
    count=0
    for file in "${city}"/*;
    do
        # echo "${file}"
        filename=$(basename ${file})
        # echo "$filename"
        target_filename="${city_name}_${filename}"
        # echo "${target_filename}"
        wo_ext="${filename%.dat}"
        echo "$wo_ext"
        item_name="${wo_ext##*_}"

        var1="${wo_ext%_*}"
        part_num="${var1##*_}"
        # echo "$item_name"
        # echo "$part_num"

        part_num=$((10#$part_num))

        echo "$part_num"

        if [[ $((part_num))%2 -eq 0 ]]; then
            ((count_map["${item_name}"]++))
        fi
        

        cp "${file}" "${dir}/${blu_dir}/${target_filename}"
    done
done

{
    for item_name in "${!count_map[@]}"; do
        echo "${item_name}: ${count_map[${item_name}]}"
    done
} > "i.txt"

sort "i.txt" > "${dir}/${txtfile}"

rm -rf "i.txt"