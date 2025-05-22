

photos_dir="photos_input"

mkdir -p "${photos_dir}/morning" "${photos_dir}/afternoon" "${photos_dir}/evening" 

morn=0
evn=0
aft=0

# morn=$((10#$morn))

# scan the image files

for photo in ${photos_dir}/*.jpg ; 
do
    [ -e ${photo} ] || continue
    echo "${photo}"

    filename=$(basename "${photo}")


    filename=${filename%.jpg}

    # echo "$filename"
    image_name=$(basename "${photo}")
    echo "$image_name"


    date_time=${filename##*_}


    hour=${date_time:0:2}

    

    hour_num=$((10#$hour))

    # echo "$hour_num"

    if [ $hour_num -ge 0 ] && [ $hour_num -le 11 ]; then
        category="morning"
        ((morn++))
    elif [ $hour_num -ge 12 ] && [ $hour_num -le 17 ]; then
        category="afternoon"
        ((aft++))
    else
        category="evening"
        ((evn++))
    fi

    target_dir="${photos_dir}/${category}/${image_name}"
    cp "${photo}" "${target_dir}"
done
{
    echo "morning count value update: $morn"
    echo "afternoon count value update: $aft"
    echo "evening count value update: $evn"
} > "${photos_dir}/count.txt"