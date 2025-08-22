#!/bin/bash

#================================================================================
# OCCULT Wrapper Script
#
# This script sets up the current directory for an OCCULT calculation by
# copying necessary scripts and templates. It takes a single .xyz file
# as an argument and automatically updates the submission script.
#================================================================================

# --- Configuration ---
# Define path to OCCULT scripts and templates.
# IMPORTANT: You may need to change these paths to match your system.
OCCULT_DIR="/wendianHome/u/au/sa/mdooley/MyScripts/occult"
TEMPLATES_DIR="/wendianHome/u/au/sa/mdooley/MyScripts/occult/templates"


# --- Input Validation ---
# Ensure exactly one argument (an .xyz file) was provided.
if [ $# -ne 1 ]; then
    echo "Usage: $0 molecule.xyz"
    exit 1
fi

XYZ_FILE="$1"

# Check that the specified xyz file exists in the current directory.
if [ ! -f "$XYZ_FILE" ]; then
    echo "Error: $XYZ_FILE not found in the current directory."
    exit 1
fi


# --- Script Setup ---
echo "Setting up OCCULT environment for $XYZ_FILE..."

# Copy all necessary scripts into the current directory.
# Using a 'for' loop to provide better feedback on copy status.
SCRIPTS_TO_COPY=(
    "censo2rc"
    "generate_goat_inp.py"
    "gsolv_process.py"
    "nsolv.py"
    "occult_part1_orca.s"
    "occult_part2_censo.s"
    "occult_part3_cosmo.s"	
    "orca_cosmo_prep.py"
    "organize_orca_jobs.py"
    "pull_cosmo_gsolv.py"
    "split_xyz_censo.sh"
)

for script in "${SCRIPTS_TO_COPY[@]}"; do
    if [ -f "$OCCULT_DIR/$script" ]; then
        cp "$OCCULT_DIR/$script" .
    else
        echo "Warning: Script '$script' not found in $OCCULT_DIR. Skipping."
    fi
done

# Create templates directory and copy template files there.
mkdir -p templates
TEMPLATES_TO_COPY=(
    "cosmors_template.inp"
    "goat.inp"
    "nsolv_template.inp"
)

for template in "${TEMPLATES_TO_COPY[@]}"; do
     if [ -f "$TEMPLATES_DIR/$template" ]; then
        cp "$TEMPLATES_DIR/$template" templates/
    else
        echo "Warning: Template '$template' not found in $TEMPLATES_DIR. Skipping."
    fi
done


# --- Automatic Configuration ---
# Automatically update the XYZ_FILE variable in the occult.s script.
# It looks for the placeholder line and replaces it with the provided filename.
echo "Updating occult.s with input file: $XYZ_FILE"
if [ -f "occult_part1_orca.s" ]; then
    # Use sed to perform an in-place replacement.
    # The pattern matches the key and its placeholder value.
    # Note on sed syntax:
    # -i'' : modify file in-place, compatible with both GNU and BSD sed.
    # s/.../.../ : substitute command
    # The use of different delimiters (#) avoids issues if filenames contain slashes.
    sed -i'' "s#XYZ_FILE=\"REPLACE.xyz\"#XYZ_FILE=\"$XYZ_FILE\"#" occult_part1_orca.s
else
    echo "Error: occult.s was not copied. Cannot update XYZ_FILE."
    exit 1
fi


# --- User Instructions ---
# Prompt user to edit the remaining critical fields in occult.s before proceeding.
echo
echo "=================================================================="
echo "Setup complete. The input file has been set automatically."
echo
echo "Please review and edit the SLURM script 'occult.s' for other settings:"
echo "  - CHARGE=0                      # Set to your molecule's charge"
echo "  - SPIN=1                        # Set to your molecule's spin"
echo "  - NSOLV=0                       # Desired number of explicit water molecules"
echo "  - Any other SLURM parameters or paths specific to your system"
echo "=================================================================="
echo

