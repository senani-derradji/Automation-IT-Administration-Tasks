#!/bin/bash
# Password Generator Project
# Day 02/09/2025

echo "------------------"
echo "| PASS GENERATOR |"
echo "------------------"

OUTPUT_FILE="passwords_$(date +%F_%H-%M).txt"
echo "Generated Passwords:" > "$OUTPUT_FILE"

echo "Entre The Length :"
read PASS_LEN

for i in $(seq 1 5);
do
	openssl rand -base64 48 | cut -c1-$PASS_LEN
done | tr -d '\n' >> "$OUTPUT_FILE"
# cat $OUTPUT_FILE
