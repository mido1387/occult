#!/bin/bash
# PART 2: CENSO (No Scratch Directory - Stable 4x9 Setup)
#SBATCH --job-name=occult_part2
#SBATCH --output=occult_part2.out
#SBATCH --error=occult_part2.err
#SBATCH --nodes=1
#SBATCH --ntasks=6
#SBATCH --cpus-per-task=6
#SBATCH --time=5-00:00:00
#SBATCH --mem-per-cpu=8G # Using 8G per CPU for robustness

echo "--- Starting Part 2: CENSO in a permanent subdirectory ---"
set -xv

# --- Environment Setup ---
# Load the modules in the same order as the successful script
module load mpi/openmpi/gcc/4.1.6  
module load apps/python3

# Set all other environment variables as before
export CONDA_ENV_PATH="/wendianHome/u/au/sa/mdooley/.conda/envs/obabel"
export PATH=$CONDA_ENV_PATH/bin:/sw/apps/orca/6.0.1/openmpi-4.1.6-avx2/bin:$PATH
export LD_LIBRARY_PATH=$CONDA_ENV_PATH/lib:/sw/apps/orca/6.0.1/openmpi-4.1.6-avx2/lib:$LD_LIBRARY_PATH
export XTBPATH=$CONDA_ENV_PATH/share/xtb
export OMP_NUM_THREADS=6
export MKL_NUM_THREADS=6

# --- Load Workflow Variables ---
ORIG_DIR=$SLURM_SUBMIT_DIR
CONFIG_FILE="$ORIG_DIR/workflow.conf"
source $CONFIG_FILE

# update solvent
bash update_censo_solvent.sh

# --- Prepare and Run CENSO in a permanent subdirectory ---
cd "$ORIG_DIR" || { echo "Failed to enter original directory"; exit 1; }

mkdir -p censo
cp "$FINAL_ENSEMBLE" censo/
cp censo2rc censo/

cd censo || { echo "Failed to enter censo directory"; exit 1; }

UNPAIRED=$((SPIN - 1))
CENSO_INPUT_FILE=$(basename "$FINAL_ENSEMBLE")

echo "Running CENSO with 6 parallel 6-core workers..."
censo -i "$CENSO_INPUT_FILE" \
      --maxcores 6 \
      --omp 6 \
      --inprc censo2rc \
      --loglevel INFO \
      --charge $CHARGE \
      --unpaired $UNPAIRED

# --- Return to the main directory ---
cd ..

# --- Handoff to Part 3 ---
# Define expected output file paths relative to the submission directory
REFINEMENT_XYZ="censo/3_REFINEMENT.xyz"
REFINEMENT_OUT="censo/3_REFINEMENT.out"

# Check if both primary output files exist before proceeding
if [[ -f "$REFINEMENT_XYZ" && -f "$REFINEMENT_OUT" ]]; then
    echo "CENSO finished. Found refinement files. Preparing next step."
    
    # Get the full, absolute paths for the next script to use
    ABSOLUTE_REFINEMENT_XYZ=$(realpath "$REFINEMENT_XYZ")
    ABSOLUTE_REFINEMENT_OUT=$(realpath "$REFINEMENT_OUT") # <-- New line

    # Append the paths for BOTH files to the central configuration file
    echo "export REFINEMENT_XYZ=\"$ABSOLUTE_REFINEMENT_XYZ\"" >> "$CONFIG_FILE"
    echo "export REFINEMENT_OUT=\"$ABSOLUTE_REFINEMENT_OUT\"" >> "$CONFIG_FILE" # <-- New line
    
    echo "Submitting Part 3 of the workflow."
    sbatch --dependency=afterok:$SLURM_JOB_ID occult_part3_cosmo.s
else
    # If a file is missing, the job failed.
    echo "FATAL ERROR: One or more refinement files not found after CENSO run."
    echo "Check for '$REFINEMENT_XYZ' and '$REFINEMENT_OUT' in the censo/ subdirectory."
    exit 1
fi