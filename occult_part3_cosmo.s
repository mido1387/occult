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

# --- Setup and Module Loading ---
set -xv
module load mpi/openmpi/gcc/4.1.6
module load apps/python3
source activate obabel

export PATH=/sw/apps/orca/6.0.1/openmpi-4.1.6-avx2/bin:$PATH
export LD_LIBRARY_PATH=/sw/apps/orca/6.0.1/openmpi-4.1.6-avx2/lib:$LD_LIBRARY_PATH

cd $SLURM_SUBMIT_DIR

# --- Load Variables from Central Config File ---
CONFIG_FILE="workflow.conf"
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
            /sw/apps/orca/6.0.0/openmpi-4.1.6/orca "$(basename "$inp_file")" > "$(basename "$inp_file" .inp).out"
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