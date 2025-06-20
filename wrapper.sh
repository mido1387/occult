#!/bin/bash

# Ensure an .xyz file was provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 molecule.xyz"
    exit 1
fi

XYZ_FILE="$1"

# Check that the xyz file exists in the current directory
if [ ! -f "$XYZ_FILE" ]; then
    echo "Error: $XYZ_FILE not found in current directory."
    exit 1
fi

# Define path to OCCULT scripts and templates
OCCULT_DIR="/beegfs/scratch/mdooley/MyScripts/OCCULT"
TEMPLATES_DIR="/beegfs/scratch/mdooley/MyScripts/OCCULT/templates"

# Copy all necessary scripts into the current directory
cp "$OCCULT_DIR"/{censo2rc,generate_goat_inp.py,gsolv_process.py,nsolv.py,occult.s,orca_cosmo_prep.py,organize_orca_jobs.py,pull_cosmo_gsolv.py,split_xyz_censo.sh} .

# Create templates directory and copy template files there
mkdir -p templates
cp "$TEMPLATES_DIR"/{cosmors_template.inp,goat.inp,nsolv_template.inp} templates/

# Prompt user to edit occult.s before proceeding
echo
echo "=================================================================="
echo "Please review and edit the SLURM script 'occult.s' as needed."
echo "Make sure to check:"
echo "  - XYZ_FILE="yourmolecule.xyz"  # Change to your input file"
echo "  - CHARGE=0 # Set to your molecules's charge"
echo "  - SPIN=1 # Set to your molecule's spin"
echo "  - NSOLV=0 # Desired number of explicit water molecules to add"
echo "  - Any other SLURM parameters or paths specific to your system"
echo
