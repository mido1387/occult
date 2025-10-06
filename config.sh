#!/bin/bash
# This is the configuration file.
# Set the path to your main ORCA installation directory.
# This folder should contain the 'bin' and 'lib' subdirectories.

ORCA_INSTALL_DIR="/sw/apps/orca/6.0.1/openmpi-4.1.6-avx2"

# Set the full path to the ORCA executable.
ORCA_EXEC="/sw/apps/orca/6.0.1/openmpi-4.1.6-avx2/orca"

# --- Software Versions ---
ORCA_VERSION="6.0.1"

# List of environment modules to load, separated by spaces. You need to make sure mpi matches your ORCA install.
REQUIRED_MODULES="mpi/openmpi/gcc/4.1.6 apps/python3"

# Name of the Conda environment to activate for Python scripts
CONDA_ENV_NAME="obabel"

# Full path to the Conda environment needed for the workflow
CONDA_ENV_PATH="/wendianHome/u/au/sa/mdooley/.conda/envs/obabel"