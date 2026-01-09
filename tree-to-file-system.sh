#!/bin/bash

##
## lankley, 01-09-2026
## TreeToFS, Linux and macOS version
##

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <file> [path]"
    exit 1
fi

FILE=$1
DEST=${2:-.}
declare -a PATHS
INDENT_SIZE=0

mkdir -p "$DEST" || exit 1

while IFS= read -r line || [ -n "$line" ]; do
    # 1. Skip comments, empty lines, or the 'directories/files' footer
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line//[[:space:]]/}" ]] && continue
    [[ "$line" =~ [0-9]+\ (directories|files) ]] && continue

    # 2. Dynamic indentation detection
    PREFIX_PART="${line%%[!│ ├└─]*}"
    if [ "$INDENT_SIZE" -eq 0 ] && [ "${#PREFIX_PART}" -gt 0 ]; then
        INDENT_SIZE=${#PREFIX_PART}
    fi

    # 3. Determine depth
    if [ "$INDENT_SIZE" -gt 0 ]; then
        DEPTH=$(( ${#PREFIX_PART} / INDENT_SIZE ))
    else
        DEPTH=0
    fi

    # 4. Extract and clean Name
    RAW_NAME="${line:${#PREFIX_PART}}"
    RAW_NAME="${RAW_NAME%[[:space:]]*}"
    
    IS_DIR=false
    if [[ "$RAW_NAME" == */ ]]; then
        IS_DIR=true
    fi

    CLEAN_NAME="${RAW_NAME%[/ *@]}"

    # 5. Update the hierarchy array
    PATHS[$DEPTH]="$CLEAN_NAME"

    # 6. Faster path construction
    SUB_PATH=$(printf "/%s" "${PATHS[@]:0:DEPTH+1}")
    FULL_PATH="${DEST}${SUB_PATH}"

    # 7. Creation logic
    if [ "$IS_DIR" = true ]; then
        mkdir -p "$FULL_PATH"
    else
        mkdir -p "$(dirname "$FULL_PATH")"
        touch "$FULL_PATH"
    fi
    
done < "$FILE"

echo "File system structure created successfully in: $DEST"
