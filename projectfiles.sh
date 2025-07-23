#!/bin/bash

# Find all *.dart files in current directory and subdirectories
# Copy them to current directory with renamed format: foldername_filename.dart.txt
# Example: lib/models/dashboard_models.dart -> lib_models_dashboard_models.dart.txt

find . -type f -name "*.dart" | while read -r file; do
  # Skip files already in the current directory to avoid copying them onto themselves
  if [[ $(dirname "$file") != "." ]]; then
    # Get the directory path and filename
    dir_path=$(dirname "$file")
    filename=$(basename "$file")

    # Replace '/' with '_' in directory path and remove leading './'
    clean_dir=$(echo "$dir_path" | sed 's/\.\///' | tr '/' '_')

    # Create new filename with foldername_filename.dart.txt format
    new_filename="${clean_dir}_${filename}.txt"

    # Copy the file to the current directory with the new name
    cp "$file" "./$new_filename"
    echo "Copied $file to ./$new_filename"
  fi
done
