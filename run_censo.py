import os
import sys
from censo.ensembledata import EnsembleData
from censo.configuration import configure
from censo.ensembleopt import Prescreening, Screening, Optimization
from censo.params import Config

print("--- Starting CENSO workflow via Python script ---")

# --- Step 1: Get Inputs from Command Line ---
if len(sys.argv) != 4:
    print("Usage: python run_censo.py <input_xyz> <charge> <spin>")
    sys.exit(1)

input_path = sys.argv[1]
charge = int(sys.argv[2])
spin = int(sys.argv[3])

# --- Step 2: Configure CENSO before running ---
print("Disabling automatic load balancing by setting 'balance' to False...")
Optimization.set_general_setting("balance", False)

# Tell CENSO the total number of cores available in the SLURM job
total_cores = int(os.environ.get('SLURM_CPUS_ON_NODE', 1))
Config.NCORES = total_cores
print(f"Configuring CENSO to use a total of {Config.NCORES} cores.")

# Tell CENSO how many threads each sub-job (like ORCA) should use.
cpus_per_task = int(os.environ.get('SLURM_CPUS_PER_TASK', 1))
Config.OMP = cpus_per_task
print(f"Configuring sub-jobs to use {Config.OMP} threads each.")

# Point to the rcfile if it exists
rcfile_path = "censo2rc"
if os.path.exists(rcfile_path):
    print(f"Configuring with rcfile: {rcfile_path}")
    configure(os.path.abspath(rcfile_path))

# --- Step 3: Load Molecule and Run Workflow ---
print(f"Reading input file: {input_path} with charge={charge} and spin={spin}")
ensemble = EnsembleData()
ensemble.read_input(input_path, charge=charge, unpaired=spin-1)

# Run the main parts of the CENSO workflow
print("Starting CENSO Optimization...")

results, timings = zip(*[part.run(ensemble) for part in [Prescreening, Screening, Optimization]])

print("--- CENSO Python script finished successfully ---")