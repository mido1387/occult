#!/bin/bash

# This script reads the SOLVENT variable from workflow.conf
# and replaces the {solvent} placeholder in the censo2rc file.

set -e # Exit immediately if a command exits with a non-zero status.

# --- Define File Paths ---
CONFIG_FILE="workflow.conf"
CENSO_FILE="censo2rc"

echo "--- Starting CENSO Solvent Configuration ---"

# --- Source Workflow Variables ---
# Check if the configuration file exists before sourcing
if [ -f "$CONFIG_FILE" ]; then
    echo "Reading configuration from $CONFIG_FILE..."
    source "./$CONFIG_FILE"
else
    echo "FATAL ERROR: Configuration file '$CONFIG_FILE' not found."
    exit 1
fi

# --- Check for CENSO File ---
if [ ! -f "$CENSO_FILE" ]; then
    echo "FATAL ERROR: CENSO configuration file '$CENSO_FILE' not found."
    exit 1
fi

# --- Check if SOLVENT variable is set ---
if [ -z "$SOLVENT" ]; then
    echo "FATAL ERROR: The 'SOLVENT' variable is not set in '$CONFIG_FILE'."
    exit 1
fi

# --- Update the CENSO File ---
echo "Updating solvent placeholder in '$CENSO_FILE' to '$SOLVENT'..."

# Use sed to perform an in-place replacement.
# The double quotes are crucial to allow the shell to expand the $SOLVENT variable.
sed -i "s/{solvent}/$SOLVENT/g" "$CENSO_FILE"

echo "Successfully updated the solvent in '$CENSO_FILE'."
echo "--- CENSO Solvent Configuration Complete ---"