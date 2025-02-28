#!/bin/sh
# finder-test.sh for Assignment 4 integration
# This script tests the finder application.
# It assumes the following executables are available in the PATH:
#   - finder.sh
#   - writer
# And it expects configuration files in /etc/finder-app:
#   - username.txt
#   - assignment.txt (which should contain "assignment4")
#
# The script writes the output of the finder command to /tmp/assignment4-result.txt.

set -e
set -u

NUMFILES=10
WRITESTR=AELD_IS_FUN
WRITEDIR=/tmp/aeld-data

# Read configuration from /etc/finder-app
username=$(cat /etc/finder-app/username.txt)

if [ $# -ge 1 ]; then
    NUMFILES=$1
fi
if [ $# -ge 2 ]; then
    WRITESTR=$2
fi
if [ $# -ge 3 ]; then
    WRITEDIR=/tmp/aeld-data/$3
fi

MATCHSTR="The number of files are ${NUMFILES} and the number of matching lines are ${NUMFILES}"

echo "Writing ${NUMFILES} files containing string ${WRITESTR} to ${WRITEDIR}"
rm -rf "${WRITEDIR}"

# Ensure the assignment configuration is correct.
assignment=$(cat /etc/finder-app/assignment.txt)
if [ "$assignment" != "assignment4" ]; then
    mkdir -p "$WRITEDIR"
    if [ -d "$WRITEDIR" ]; then
        echo "$WRITEDIR created"
    else
        exit 1
    fi
fi

# Use the writer command (assumed to be in the PATH)
for i in $(seq 1 $NUMFILES); do
    writer "$WRITEDIR/${username}$i.txt" "$WRITESTR"
done

# Call finder.sh (assumed to be in the PATH)
OUTPUTSTRING=$(finder.sh "$WRITEDIR" "$WRITESTR")
rm -rf /tmp/aeld-data

echo "${OUTPUTSTRING}" > /tmp/assignment4-result.txt

echo "${OUTPUTSTRING}" | grep "${MATCHSTR}"
if [ $? -eq 0 ]; then
    echo "success"
    exit 0
else
    echo "failed: expected ${MATCHSTR} in ${OUTPUTSTRING}"
    exit 1
fi

