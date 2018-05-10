#!/bin/bash

set -x

# Bash dir
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Create sample content
rm -Rf $DIR/origin $DIR/latest
mkdir -p $DIR/origin/sample $DIR/latest
rm -f $DIR/origin/*
dd if=/dev/zero of=$DIR/origin/sample/file1 bs=1K count=128
dd if=/dev/zero of=$DIR/origin/sample/file2 bs=1K count=128
dd if=/dev/zero of=$DIR/origin/sample/file3 bs=1K count=128

# # Start backup process
echo ""
echo ""
echo "STARTING MAIN PROCESS"
$DIR/backup.sh $DIR/origin $DIR/latest

# # Remove all files
rm -Rf $DIR/origin $DIR/latest
