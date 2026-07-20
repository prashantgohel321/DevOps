#!/usr/bin/env bash

for file in Day\ *.md; do
    # Extract the numeric part after "Day "
    day=$(echo "$file" | sed -n 's/^Day \([0-9]\+\).*/\1/p')

    # Skip if extraction failed
    [ -z "$day" ] && continue

    # Convert explicitly to base-10 to avoid octal issues
    day_dec=$((10#$day))

    # Skip Day 100
    [ "$day_dec" -eq 100 ] && continue

    # Pad to three digits
    newday=$(printf "%03d" "$day_dec")

    # Construct new filename
    newfile=$(echo "$file" | sed "s/^Day $day/Day $newday/")

    # Dry-run (remove echo after verification)
    mv "$file" "$newfile"
done

