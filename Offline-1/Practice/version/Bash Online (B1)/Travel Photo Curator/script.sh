#!/bin/bash

# Define the photos directory
photos_dir="photos_input"

# Create subdirectories if they don't exist
mkdir -p "${photos_dir}/morning" "${photos_dir}/afternoon" "${photos_dir}/evening"

# Initialize counters
morning_count=0
afternoon_count=0
evening_count=0

# Process each photo in the directory
for photo in "${photos_dir}"/IMG.*.jpg; do
    # Skip if no files found (to prevent processing the literal pattern)
    [ -e "$photo" ] || continue
    
    # Extract filename without path
    filename=$(basename "$photo")
    
    # Extract hour from filename (positions 15-16 after IMG.YYYYMMDD_)
    hour=${filename:15:2}
    
    # Remove leading zero for numeric comparison
    hour_num=$((10#$hour))
    
    # Determine time category
    if [ $hour_num -ge 0 ] && [ $hour_num -le 11 ]; then
        category="morning"
        ((morning_count++))
    elif [ $hour_num -ge 12 ] && [ $hour_num -le 17 ]; then
        category="afternoon"
        ((afternoon_count++))
    else
        category="evening"
        ((evening_count++))
    fi
    
    # Move and rename the file
    new_filename="${category}_${filename}"
    mv "$photo" "${photos_dir}/${category}/${new_filename}"
done

# Generate counts.txt file
{
    echo "morning: $morning_count"
    echo "afternoon: $afternoon_count"
    echo "evening: $evening_count"
} > "${photos_dir}/counts.txt"

echo "Photo organization complete!"
echo "Counts saved to ${photos_dir}/counts.txt"