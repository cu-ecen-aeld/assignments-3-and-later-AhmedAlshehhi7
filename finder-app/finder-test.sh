#!/bin/sh
# finder-test.sh: Test script for the finder and writer utilities.
# This script writes a specified number of files containing a given string,
# then runs finder.sh to count the files and matching lines.
# Configuration files are expected in /etc/finder-app/conf.

set -e
set -u

# Default values
NUMFILES=10
WRITESTR="AELD_IS_FUN"
WRITEDIR="/tmp/aeld-data"

# Read configuration values
username=$(cat /etc/finder-app/conf/username.txt)
assignment=$(cat /etc/finder-app/conf/assignment.txt)

# Override defaults if command line arguments are provided
if [ "$#" -ge 1 ]; then
    NUMFILES=$1
fi
if [ "$#" -ge 2 ]; then
    WRITESTR=$2
fi
if [ "$#" -ge 3 ]; then
    WRITEDIR="/tmp/aeld-data/$3"
fi

MATCHSTR="The number of files are ${NUMFILES} and the number of matching lines are ${NUMFILES}"

echo "Writing ${NUMFILES} files containing string ${WRITESTR} to ${WRITEDIR}"

# Remove any previous directory
rm -rf "${WRITEDIR}"

# Create WRITEDIR if assignment is not 'assignment1'
if [ "$assignment" != "assignment1" ]; then
    mkdir -p "$WRITEDIR"
    if [ -d "$WRITEDIR" ]; then
        echo "$WRITEDIR created"
    else
        echo "Failed to create $WRITEDIR" >&2
        exit 1
    fi
fi

# Write files using the writer utility (using its absolute path)
i=1
while [ $i -le $NUMFILES ]; do
    /bin/writer "$WRITEDIR/${username}$i.txt" "$WRITESTR"
    i=$(( i + 1 ))
done

# Run finder.sh using its absolute path and redirect output
/bin/finder.sh "$WRITEDIR" "$WRITESTR" > /tmp/assignment4-result.txt

echo "Finder test completed. Results stored in /tmp/assignment4-result.txt"

