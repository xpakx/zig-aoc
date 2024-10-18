#!/bin/bash

DIR="."
TEMPLATE_FILE="day01.zig"
BUILD_FILE="build.zig"

highest_num=0
for file in "$DIR"/src/day??.zig; do
    if [[ -f "$file" ]]; then
        num=$(basename "$file" | grep -o -E '[0-9]{2}')
        if [[ $num -gt $highest_num ]]; then
            highest_num=$num
        fi
    fi
done
echo $highest_num

if [[ $highest_num -ge 25 ]]; then
    echo "No action taken: highest day is $highest_num (>= 25)."
    exit 0
fi

new_num=$((10#$highest_num + 1))
formatted_new_num=$(printf "%02d" "$new_num")
echo $new_num

cp "$DIR/src/$TEMPLATE_FILE" "$DIR/src/day$formatted_new_num.zig"

# Update the line 9 in build.zig
sed -i "9s/[0-9]\+/$new_num/" "$BUILD_FILE"

echo "Created day$new_num.zig and updated $BUILD_FILE."

