#!/bin/bash
# PART 3: Final ORCA Jobs and Processing (MPI Parallel)
#SBATCH --job-name=occult_part3
#SBATCH --output=occult_part3.out
#SBATCH --error=occult_part3.err
#SBATCH --nodes=1
#SBATCH --ntasks=36
#SBATCH --cpus-per-task=1
#SBATCH --time=2-00:00:00

echo "--- Starting Part 3: Final ORCA Jobs and Analysis ---"

# 1. Source the configuration file using the script's path.
source "${SLURM_SUBMIT_DIR}/config.sh"

# 2. Check if the ORCA_INSTALL_DIR variable was loaded correctly.
if [ -z "$ORCA_INSTALL_DIR" ] || [ ! -d "$ORCA_INSTALL_DIR" ]; then
  echo "Error: ORCA_INSTALL_DIR is not set or not a valid directory in config.sh." >&2
  exit 1
fi

# --- Setup and Module Loading ---
set -e #change the e to xv for verbose debugging
# Load modules specified in the config file
if [ -n "$REQUIRED_MODULES" ]; then
  echo "Loading modules: $REQUIRED_MODULES"
  module load $REQUIRED_MODULES
else
  echo "No modules specified in config file."
fi

# Activate Conda environment
if [ -n "$CONDA_ENV_NAME" ]; then
  echo "Activating Conda environment: $CONDA_ENV_NAME"
  # Assuming 'conda' is available after loading modules or is in the default PATH
  source activate "$CONDA_ENV_NAME"
else
  echo "Error: CONDA_ENV_NAME is not set in config.sh." >&2
  exit 1
fi

echo "Setting up environment for ORCA installation at: $ORCA_INSTALL_DIR"
export PATH="${ORCA_INSTALL_DIR}/bin:$PATH"
export LD_LIBRARY_PATH="${ORCA_INSTALL_DIR}/lib:$LD_LIBRARY_PATH"

cd $SLURM_SUBMIT_DIR

# --- Load Variables from Central Config File ---
CONFIG_FILE="${SLURM_SUBMIT_DIR}/workflow.conf"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "FATAL ERROR: $CONFIG_FILE not found!"
    exit 1
fi
source $CONFIG_FILE

# --- Prepare and Process CENSO Output ---
mkdir -p orca_cosmo
cp "$REFINEMENT_XYZ" orca_cosmo/
cp "$REFINEMENT_OUT" orca_cosmo/

cd orca_cosmo || { echo "Failed to enter orca_cosmo directory"; exit 1; }

bash ../split_xyz_censo.sh "$(basename "$REFINEMENT_XYZ")"
python ../orca_cosmo_prep.py --charge $CHARGE --spin $SPIN --solvent $SOLVENT 
python ../organize_orca_jobs.py
cd ..

# --- Run Final ORCA Loop ---
for conf_dir in orca_cosmo/CONF*/; do
    inp_file=$(find "$conf_dir" -name "*.inp" | head -n 1)
    if [[ -n "$inp_file" ]]; then
        echo "Running ORCA in $conf_dir on $(basename $inp_file)..."
        # The ORCA command is run inside a subshell to isolate the directory change
        (
            cd "$(dirname "$inp_file")" || exit
            "$ORCA_EXEC" "$(basename "$inp_file")" > "$(basename "$inp_file" .inp).out"
        )
    else
        echo "No .inp file found in $conf_dir, skipping."
    fi
done

# --- Final Analysis ---
cd orca_cosmo
python ../pull_cosmo_gsolv.py
python ../gsolv_process.py
cd ..

echo "--- Workflow complete. ---"