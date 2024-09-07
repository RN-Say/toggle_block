#!/bin/bash

# Arguments passed from the automation or command line
target_block="$1"
toggle_state="$2"
target_file="$3"
backup="${4:-on}"  # Default to 'on' if not provided

# Check if a full path is provided for target_file, otherwise default to /config
if [[ "$target_file" != /* ]]; then
    target_file="/config/$target_file"
fi

# Check if YAML file exists
if [ ! -f "$target_file" ]; then
    echo "Error: The file '$target_file' does not exist."
    exit 1
fi

# Check if block name is valid, ignoring comments
if ! grep -q "^[[:space:]]*#\?<$target_block>" "$target_file" || ! grep -q "^[[:space:]]*#\?</$target_block>$" "$target_file"; then
    echo "Error: The block name '$target_block' does not exist in '$target_file'."
    exit 1
fi

# If the toggle_state is 'show', display the block content with tags and add a blank line between blocks
if [ "$toggle_state" = "show" ]; then
    echo "Showing block '$target_block':"
    # Print the block content and add a blank line after the closing tag
    sed -n "/^[[:space:]]*#<$target_block>/,/^[[:space:]]*#<\/$target_block>/p" "$target_file" | awk '/<\/'$target_block'>/{print;print "";next}1'
    exit 0
fi

# Check if toggle_state is valid
if [ "$toggle_state" != "on" ] && [ "$toggle_state" != "off" ]; then
    echo "Error: Invalid state '$toggle_state'. Use 'on' to uncomment, 'off' to comment, or 'show' to display the block."
    exit 1
fi

# Check backup flag and create a backup unless it's explicitly "off" or "no_backup"
if [ "$backup" != "off" ] && [ "$backup" != "no_backup" ] && [ "$toggle_state" != "show" ]; then
    cp "$target_file" "${target_file}.bak"
    echo "Backup created: ${target_file}.bak"
fi

# Perform the action based on the state
if [ "$toggle_state" = "on" ]; then
    # Uncomment the block
    sed -i "/^[[:space:]]*#<$target_block>/,/^[[:space:]]*#<\/$target_block>/ { /^[[:space:]]*#<$target_block>/! { /^[[:space:]]*#<\/$target_block>/! s/^\([[:space:]]*\)# \([[:space:]]*\)/\1\2/ } }" "$target_file"
    echo "The block '$target_block' has been uncommented."
    # Print the block content and add a blank line after the closing tag
    sed -n "/^[[:space:]]*#<$target_block>/,/^[[:space:]]*#<\/$target_block>/p" "$target_file" | awk '/<\/'$target_block'>/{print;print "";next}1'
    
else
    # Comment the block
    sed -i "/^[[:space:]]*#<$target_block>/,/^[[:space:]]*#<\/$target_block>/ { /^[[:space:]]*#<$target_block>/! { /^[[:space:]]*#<\/$target_block>/! { /^[[:space:]]*#/! s/^\([[:space:]]*\)\(.*\)/\1# \2/ } } }" "$target_file"
    echo "The block '$target_block' has been commented."
    # Print the block content and add a blank line after the closing tag
    sed -n "/^[[:space:]]*#<$target_block>/,/^[[:space:]]*#<\/$target_block>/p" "$target_file" | awk '/<\/'$target_block'>/{print;print "";next}1'
    
fi
