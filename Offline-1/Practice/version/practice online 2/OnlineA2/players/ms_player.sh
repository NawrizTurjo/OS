find . -type f -iname '*.txt' | while read -r file;
do
    mapfile -t lines < <(grep -v '^[[:space:]]*$' "$file")

    # echo "${lines[0]}"
    name="${lines[0]}"
    # echo "$name"
    # echo "${lines[1]}"
    folder_name="${lines[1]}"
    # echo "$folder_name"

    # echo "${lines[2]}"
    role="${lines[2]}"
    echo "$role"
    mkdir -p "$folder_name/$role"

    cp "$file" "$folder_name/$role"
done