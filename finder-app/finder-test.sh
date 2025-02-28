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

# Default values
NUMFILES=10
WRITESTR="AELD_IS_FUN"
WRITEDIR="/tmp/aeld-data"

# Read the username from the configuration file
username=$(cat /etc/finder-app/username.txt)

# Allow overriding defaults via script parameters
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

# Verify that the assignment configuration is correct
assignment=$(cat /etc/finder-app/assignment.txt)
if [ "$assignment" != "assignment4" ]; then
    echo "Warning: Expected assignment to be 'assignment4', but got '$assignment'"
    mkdir -p "$WRITEDIR"
fi

# Use the writer command to create files
for i in $(seq 1 $NUMFILES); do
    writer "$WRITEDIR/${username}$i.txt" "$WRITESTR"
done

# Run the finder command (finder.sh should be in the PATH)
OUTPUTSTRING=$(finder.sh "$WRITEDIR" "$WRITESTR")
rm -rf "${WRITEDIR}"

# Write the output to /tmp/assignment4-result.txt
echo "${OUTPUTSTRING}" > /tmp/assignment4-result.txt

# Check that the output contains the expected match string
echo "${OUTPUTSTRING}" | grep "${MATCHSTR}"
if [ $? -eq 0 ]; then
    echo "success"
    exit 0
else
    echo "failed: expected ${MATCHSTR} in output: ${OUTPUTSTRING}"
    exit 1
fi

