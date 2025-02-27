#!/bin/sh
# finder-test.sh for Assignment 4 integration
# This script expects the following to be installed in the target:
#   - finder.sh, writer, finder-test.sh in /usr/bin
#   - Configuration files in /etc/finder-app
# It writes the finder command output to /tmp/assignment4-result.txt.

set -e
set -u

NUMFILES=10
WRITESTR=AELD_IS_FUN
WRITEDIR=/tmp/aeld-data

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

assignment=$(cat /etc/finder-app/assignment.txt)
if [ "$assignment" != "assignment1" ]; then
    mkdir -p "$WRITEDIR"
    if [ -d "$WRITEDIR" ]; then
        echo "$WRITEDIR created"
    else
        exit 1
    fi
fi

# Use writer application (assumed to be in PATH, e.g., /usr/bin)
for i in $(seq 1 $NUMFILES); do
    writer "$WRITEDIR/${username}$i.txt" "$WRITESTR"
done

# Call finder.sh (assumed to be in PATH, e.g., /usr/bin)
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

