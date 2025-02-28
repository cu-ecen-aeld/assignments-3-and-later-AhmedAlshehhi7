#!/bin/sh
# finder-test.sh for Assignment 4 integration
# This script tests the finder application.
# It assumes the following executables are in the PATH:
#   - finder.sh
#   - writer
# It expects configuration files to be located in /etc/finder-app:
#   - username.txt
#   - assignment.txt (which should contain "assignment4")
# The script writes the output of the finder command to /tmp/assignment4-result.txt.

set -e
set -u

NUMFILES=10
WRITESTR="AELD_IS_FUN"
WRITEDIR="/tmp/aeld-data"

username=$(cat /etc/finder-app/username.txt)

if [ $# -ge 1 ]; then
    NUMFILES=$1
fi
if [ $# -ge 2 ]; then
    WRITESTR=$2
fi
if [ $# -ge 3 ]; then
    WRITEDIR=$3
fi

MATCHSTR="The number of files are ${NUMFILES} and the number of matching lines are ${NUMFILES}"

echo "Writing ${NUMFILES} files containing string ${WRITESTR} to ${WRITEDIR}"
rm -rf "${WRITEDIR}"

assignment=$(cat /etc/finder-app/assignment.txt)
if [ "$assignment" != "assignment4" ]; then
    mkdir -p "$WRITEDIR"
    if [ -d "$WRITEDIR" ]; then
        echo "$WRITEDIR created"
    else
        exit 1
    fi
fi

for i in $(seq 1 $NUMFILES); do
    writer "$WRITEDIR/${username}$i.txt" "$WRITESTR"
done

OUTPUTSTRING=$(finder.sh "$WRITEDIR" "$WRITESTR")
rm -rf "${WRITEDIR}"

echo "${OUTPUTSTRING}" > /tmp/assignment4-result.txt

echo "${OUTPUTSTRING}" | grep "${MATCHSTR}"
if [ $? -eq 0 ]; then
    echo "success"
    exit 0
else
    echo "failed: expected ${MATCHSTR} in ${OUTPUTSTRING}"
    exit 1
fi

