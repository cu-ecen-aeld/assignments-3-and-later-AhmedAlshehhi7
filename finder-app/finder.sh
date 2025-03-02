#!/bin/sh
# finder.sh: search for a string in all files within a directory

if [ "$#" -ne 2 ]; then
    echo >&2 "Usage: $0 filesdir searchstr"
    exit 1
fi

filesdir=$1
searchstr=$2

if [ ! -d "$filesdir" ]; then
    echo >&2 "$0: $filesdir is not a directory"
    exit 1
fi

files=0
lines=0

# Use find to iterate over files recursively
for f in $(find "$filesdir" -type f); do
    files=$((files + 1))
    count=$(grep "$searchstr" "$f" | wc -l)
    lines=$((lines + count))
done

echo "The number of files are $files and the number of matching lines are $lines"
exit 0

