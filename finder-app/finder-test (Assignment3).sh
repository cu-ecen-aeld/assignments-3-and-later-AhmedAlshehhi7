#!/bin/sh
# Modified finder-test.sh to use pre-built writer and absolute path for finder.sh

# Change directory to /home to ensure the files are found
cd /home

set -e
set -u

NUMFILES=10
WRITESTR=AELD_IS_FUN
WRITEDIR=/tmp/aeld-data

username=$(cat /home/conf/username.txt)

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

assignment=$(cat /home/conf/assignment.txt)
if [ "$assignment" != "assignment1" ]; then
    mkdir -p "$WRITEDIR"
    if [ -d "$WRITEDIR" ]; then
        echo "$WRITEDIR created"
    else
        exit 1
    fi
fi

# Use the pre-built writer application (in /home)
for i in $(seq 1 $NUMFILES); do
    ./writer "$WRITEDIR/${username}$i.txt" "$WRITESTR"
done

# Call finder.sh using its absolute path
OUTPUTSTRING=$(sh /home/finder.sh "$WRITEDIR" "$WRITESTR")
rm -rf /tmp/aeld-data

echo "${OUTPUTSTRING}" | grep "${MATCHSTR}"
if [ $? -eq 0 ]; then
    echo "success"
    exit 0
else
    echo "failed: expected ${MATCHSTR} in ${OUTPUTSTRING}"
    exit 1
fi

