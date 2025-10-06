#!/bin/bash

# This script creates the censo2rc file by populating a template
# with variables from config.sh and workflow.conf.

set -e # Exit immediately if a command exits with a non-zero status.

# --- Define File Paths ---
MASTER_CONFIG="config.sh"
WORKFLOW_CONFIG="workflow.conf"
TEMPLATE_FILE="censo2rc.template"
OUTPUT_FILE="censo2rc"

echo "--- Starting CENSO File Preparation ---"

# --- Source Configurations ---
source "./$MASTER_CONFIG"
source "./$WORKFLOW_CONFIG"

# --- Validate All Required Variables ---
# (It's good practice to add checks here for all variables)

# --- Create a working copy from the template ---
echo "Creating '$OUTPUT_FILE' from '$TEMPLATE_FILE'..."
cp "$TEMPLATE_FILE" "$OUTPUT_FILE"

# --- Update All Placeholders in the CENSO File ---
echo "Updating placeholders for paths and solvent..."

# Use a single sed command with multiple expressions (-e) for efficiency.
# NOTE: We use '|' as the separator instead of '/' to safely handle file paths.
sed -i \
    -e "s|{orcapath}|${ORCA_INSTALL_DIR}/orca|g" \
    -e "s|{xtbpath}|${CONDA_ENV_PATH}/bin/xtb|g" \
    -e "s|{orcaversion}|${ORCA_VERSION}|g" \
    -e "s|{solvent}|${SOLVENT}|g" \
    "$OUTPUT_FILE"

echo "Successfully updated '$OUTPUT_FILE'."
echo "--- CENSO File Preparation Complete ---"