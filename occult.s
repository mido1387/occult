#!/bin/bash
#SBATCH --job-name=occult_workflow
#SBATCH --account=2101080209
#SBATCH --output=occult.out
#SBATCH --error=occult.err
#SBATCH --nodes=1
#SBATCH --mincpus=36
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=9
#SBATCH -q normal
#SBATCH --export=ALL
#SBATCH --time=5-23:59:59

# Load Python and ORCA
module load mpi/openmpi/gcc/4.1.6
module load apps/python3

source activate obabel  # Replace 'obabel' with your conda environment name

# Ensure ORCA uses the correct OpenMPI version
export PATH=/sw/apps/orca/6.0.1/openmpi-4.1.6-avx2/bin:$PATH
export LD_LIBRARY_PATH=/sw/apps/orca/6.0.1/openmpi-4.1.6-avx2/lib:$LD_LIBRARY_PATH

# Set variables manually
XYZ_FILE="REPLACE.xyz"  # Change to your input file
CHARGE=0
SPIN=1
NSOLV=0

# Prevent Oversubscribing Cores for CENSO (unseen steps, does not affect ORCA/xtb parallelization)
export OMP_NUM_THREADS=4
export MKL_NUM_THREADS=4
export OPENBLAS_NUM_THREADS=4
export NUMEXPR_NUM_THREADS=4

# XTB Parallelization (TEST)
export XTB_NUM_THREADS=4

# make slurm verbose and log more
set -xv
env > slurm.env.log

# Go to the working directory
cd $SLURM_SUBMIT_DIR

# Step 1: Generate solvated ORCA input using nsolv.py
python nsolv.py $NSOLV $XYZ_FILE $CHARGE $SPIN

# Step 2: Run ORCA on the .inp file created inside the 'nsolv' folder
BASENAME=$(basename "$XYZ_FILE" .xyz)
SOLV_INP="nsolv/${BASENAME}_nsolv_${NSOLV}.inp"
/sw/apps/orca/6.0.0/openmpi-4.1.6/orca "$SOLV_INP" > "${SOLV_INP%.inp}.out"

# Step 3: Copy the solvator.xyz file from the 'nsolv' folder
SOLV_XYZ="nsolv/${BASENAME}_nsolv_${NSOLV}.solvator.xyz" 
cp "$SOLV_XYZ" .

# Step 4.0 Label fragments - TODO
# python label_fragments.py "${BASENAME}_nsolv_${NSOLV}.solvator.xyz" ${NSOLV} --output "${BASENAME}_nsolv_${NSOLV}.solvator_fragmented.xyz"

# Step 4.1 Detect Hbonds - TODO
# python hbond_finder.py "${BASENAME}_nsolv_${NSOLV}.solvator_fragmented.xyz"

# Step 4: Generate GOAT input
python generate_goat_inp.py "${BASENAME}_nsolv_${NSOLV}.solvator.xyz" $CHARGE $SPIN --nsolv ${NSOLV}

# Step 5: Run ORCA on the GOAT input
GOAT_INP="goat/${BASENAME}_nsolv_${NSOLV}.goat.inp" 
/sw/apps/orca/6.0.0/openmpi-4.1.6/orca "$GOAT_INP" > "${GOAT_INP%.inp}.out"

# Step 6: Prepare input for CENSO
# Identify the finalensemble.xyz file in goat/
FINAL_ENSEMBLE=$(find goat -name "*finalensemble.xyz" | head -n 1)

if [[ -f "$FINAL_ENSEMBLE" ]]; then
    cp "$FINAL_ENSEMBLE" .

    # Make censo directory and copy necessary files
    mkdir -p censo
    cp "$(basename "$FINAL_ENSEMBLE")" censo/
    cp censo2rc censo/
else
    echo "Error: finalensemble.xyz not found in goat/"
    exit 1
fi

# Step 7: Run CENSO

# Environment troubleshooting
# echo "ENVIRONMENT"
# env
# echo "PWD: $(pwd)"
# echo "TMPDIR: $TMPDIR"
# ulimit -a

UNPAIRED=$((SPIN - 1))  # ORCA spin -> unpaired electrons

cd censo || { echo "Failed to enter censo directory"; exit 1; }

censo -i "$(basename "$FINAL_ENSEMBLE")" \
      --maxcores 4 \
      --omp 4 \
      --inprc censo2rc \
      --loglevel DEBUG \
      --charge $CHARGE \
      --unpaired $UNPAIRED
cd ..

# Step 8: Prepare and process CENSO output
mkdir -p orca_cosmo  # Create the orca_cosmo directory if it doesn't exist

# Copy refinement output files from censo to orca_cosmo
cp censo/3_REFINEMENT.xyz orca_cosmo/
cp censo/3_REFINEMENT.out orca_cosmo/

# Change to the orca_cosmo directory and run the split_censo_xyz script
cd orca_cosmo || { echo "Failed to enter orca_cosmo directory"; exit 1; }

bash ../split_xyz_censo.sh 3_REFINEMENT.xyz

# Step 9: Prepare ORCA COSMO input files
python ../orca_cosmo_prep.py --charge $CHARGE --spin $SPIN

# Step 10: Organize CONF*_COSMO.* files into numbered folders
python ../organize_orca_jobs.py

# Step 11: Run ORCA on each CONF# job in orca_cosmo
cd ..

for conf_dir in orca_cosmo/CONF*/; do
    shopt -s nullglob  # make sure globs that don't match return empty
    inp_files=("$conf_dir"*.inp)
    shopt -u nullglob  # restore default behavior

    if [ ${#inp_files[@]} -gt 0 ]; then
        inp_file="${inp_files[0]}"
        echo "Running ORCA in $conf_dir on $inp_file..."
        (
            cd "$conf_dir" || exit
            /sw/apps/orca/6.0.0/openmpi-4.1.6/orca "$(basename "$inp_file")" > "$(basename "$inp_file" .inp).out"
        )
    else
        echo "No .inp file found in $conf_dir, skipping."
    fi
done

# Step 12: Pull all of the COSMO-RS results
cd orca_cosmo

python ../pull_cosmo_gsolv.py

# Step 13: Use all of the COSMO-RS results and the Boltzmann weights from CENSO to calculate Gsolv
python ../gsolv_process.py







