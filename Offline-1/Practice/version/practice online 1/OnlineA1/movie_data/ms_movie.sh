for file in ./*.txt;
do
    director_name=$( tail -n 2 "${file}"| head -n 1)
    file_name=$( basename "${file}")
    echo "${director_name}"
    echo "${file_name}"

    mkdir -p "${director_name}"

    cp "${file_name}" "${director_name}"
done