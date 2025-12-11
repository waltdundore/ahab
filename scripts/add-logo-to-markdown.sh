#!/usr/bin/env bash
# Add Ahab logo to all markdown files

set -euo pipefail

# Find all markdown files in ahab directory
find . -name "*.md" -type f | while read -r file; do
    # Skip if already has the logo
    if grep -q "ahab-logo.png" "$file"; then
        echo "✓ Logo already present: $file"
        continue
    fi
    
    # Calculate relative path to docs/images/ahab-logo.png
    file_dir=$(dirname "$file")
    depth=$(echo "$file_dir" | tr -cd '/' | wc -c)
    
    # Build relative path
    if [ "$depth" -eq 1 ]; then
        rel_path="docs/images/ahab-logo.png"
    else
        rel_path=""
        for ((i=1; i<depth; i++)); do
            rel_path="../$rel_path"
        done
        rel_path="${rel_path}docs/images/ahab-logo.png"
    fi
    
    # Read first line
    first_line=$(head -n 1 "$file")
    
    # If first line is a heading, add logo after it
    if [[ "$first_line" =~ ^#\  ]]; then
        # Create temp file with logo inserted
        {
            echo "$first_line"
            echo ""
            echo "![Ahab Logo]($rel_path)"
            tail -n +2 "$file"
        } > "${file}.tmp"
        
        mv "${file}.tmp" "$file"
        echo "✓ Added logo to: $file"
    else
        echo "⚠ Skipped (no heading): $file"
    fi
done

echo ""
echo "Logo addition complete!"
