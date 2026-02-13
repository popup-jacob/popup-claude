#!/bin/bash
# ============================================
# FR-S1-11: SHA-256 Checksum Generator
# ============================================
# Generates checksums.json for all installer files.
# Run from the installer/ directory or CI/CD pipeline.
#
# Usage:
#   cd installer && ./generate-checksums.sh
#   # or
#   ./installer/generate-checksums.sh /path/to/installer

set -e

BASE_DIR="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
OUTPUT="$BASE_DIR/checksums.json"

echo "Generating checksums for files in: $BASE_DIR"

# Start JSON
echo '{' > "$OUTPUT"
echo '  "version": "1.0",' >> "$OUTPUT"
echo '  "algorithm": "sha256",' >> "$OUTPUT"
echo "  \"generated\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"," >> "$OUTPUT"
echo '  "files": {' >> "$OUTPUT"

first=true
cd "$BASE_DIR"

# Hash all relevant files
for file in modules.json modules/*/module.json modules/*/install.sh modules/*/install.ps1; do
    if [ -f "$file" ]; then
        # Compute SHA-256 (cross-platform)
        if command -v shasum > /dev/null 2>&1; then
            hash=$(shasum -a 256 "$file" | awk '{print $1}')
        elif command -v sha256sum > /dev/null 2>&1; then
            hash=$(sha256sum "$file" | awk '{print $1}')
        else
            echo "ERROR: No SHA-256 tool found"
            exit 1
        fi

        if [ "$first" = true ]; then
            first=false
        else
            echo ',' >> "$OUTPUT"
        fi

        printf '    "%s": "%s"' "$file" "$hash" >> "$OUTPUT"
    fi
done

echo '' >> "$OUTPUT"
echo '  }' >> "$OUTPUT"
echo '}' >> "$OUTPUT"

echo "Checksums written to: $OUTPUT"
echo "Files hashed: $(grep -c '"modules' "$OUTPUT" || echo 0)"
