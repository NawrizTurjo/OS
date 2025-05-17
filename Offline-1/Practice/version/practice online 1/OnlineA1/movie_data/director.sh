#!/bin/bash
#
# Move each movie–text file into a folder named
# after its director (the line before the 4-digit year).

for file in *.txt; do
    # 1️⃣ only regular files
    [[ -f "$file" ]] || continue # skip if not a file
    

    

    # 2️⃣ grab the candidate director
    director=$(grep -v '^[[:space:]]*$' "$file" \
               | tail -2 \
               | head -1)

    # 3️⃣ sanity checks: non-empty, not a year
    if [[ -z "$director" ]] || [[ "$director" =~ ^[0-9]{4}$ ]]; then
        # nothing to do if it's blank or actually the year
        continue
    fi

    # 4️⃣ make the director folder if needed
    mkdir -p "$director"

    # 5️⃣ move the movie file into it
    cp -- "$file" "$director/"
done
