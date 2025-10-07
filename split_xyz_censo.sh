#!/bin/bash

# Check if input file is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 input.xyz"
  exit 1
fi

# Extract the base name of the input file (without the extension)
base_name=$(basename "$1" .xyz)

# Initialize variables
output_file=""
atom_count=0
line_count=0
second_line=""

# Read the .xyz file line by line
while read -r line; do
  # If it's the beginning of a new molecule (line with atom count)
  if [[ $line =~ ^[0-9]+$ ]]; then
    atom_count=$line
    line_count=1
  elif [[ $line_count -eq 1 ]]; then
    # Second line: extract it for filename
    second_line="$line"
    
    # Clean the second line to create a valid filename (remove spaces, slashes, etc.)
    safe_name=$(echo "$second_line" | tr -cs '[:alnum:]' '_' | sed 's/^_//;s/_$//')
    
    output_file="${base_name}_${safe_name}.xyz"
    
    echo "Creating $output_file"
    
    # Write the atom count and second line to the output file
    echo "$atom_count" > "$output_file"
    echo "$second_line" >> "$output_file"
    
    line_count=2
  else
    # Write atom coordinates to the file
    echo "$line" >> "$output_file"
    line_count=$((line_count + 1))
    
    # Stop when we have processed all atom lines
    if [[ $line_count -gt $((atom_count + 1)) ]]; then
      line_count=0
    fi
  fi
done < "$1"
