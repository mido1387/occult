# ORCA CENSO COSMO-RS ULTIMATE (OCCULT) workflow

This package uses slurm scripts to automatically:
1. Preoptimize an input .xyz geometry
2. Add explicit solvent molecules (if desired) with ORCA's SOLVATOR (driven by XTB)
3. Generate a massive ensemble of conformers with the Global Optimizer Algorithm (GOAT) in ORCA
4. Sort and optimize the ensemble down to the best conformers, rank them with a Boltzman distribution using Command line Ensemble-Sorting (CENSO)
  4a. Screen conformers with XTB (can be changed by user)
  4b. Screen remaining confomers with r2scan-3c (can be changed by user)
  4c. optimize best confomers with wB97x-v/def2-TZVP (can be changed by user)
5. Calculate solvation free energy of best conformers using openCOSMO-RS

From just an input .xyz you now have a list of optimized conformers as well as a solvation energy, with explicit solvent included if desired.

**Do you want to use this version of occult? here are the quick instructions:**

## Requirements
ORCA 6.0.0+
SLURM managed computer
XTB 
Python 3 
Conda environment with: CENSO, openbabel and pandas installed

CENSO/XTB manual : https://xtb-docs.readthedocs.io/en/latest/CENSO_docs/censo.html

## Installation
Download the zip folder of the code on this page and unzip into a desired directory on your machine.
Update eveything in the config.sh file to match your ORCA/XTB/Conda environment (with CENSO installed)
uUpdate the two filepaths OCCULT_DIR and TEMPLATES_DIR in wrapper.sh to wherever you put the occult scripts into

## Use instructions
Normal use: place the wrapper.sh and your .xyz file (doesn't need to be optimized) in the same folder and:
`bash wrapper.sh YOURMOLECULE.xyz`
where YOURMOLECULE referes to your specific .xyz file (ex methane.xyz)

It will then prompt you to edit a few lines in occult_part1_orca.s, CHARGE, SPIN, and NSOLV, where nsolv is the number
of explicit waters you would like to add (can be changed to another solvent by editing the nsolv template) and SOLVENT, 
where you pick the solvent (make sure it is supportde by ALPB and openCOSMO by checking their webpages). Open occult_part1_orca.s
and change these values accordingly (lines 12-16). The wrapper should automatically update the molecule name. Default settings are charge 0,
spin multiplicity 1, no explicit solvation, and implicit solvation with water on. The other .s files do not need to be modified. 

Once it has been modified run: 
`sbatch occult_part1_orca.s`
Once that is done it will automatically run the other two scripts. 

If you have a orca_cosmo folder with a weighted_results.csv in it, then the job was successful, if not, start by looking in the censo folder for any errors.

The final optimized geometries and energies are found it the 3_REFINEMENT.xyz and 3_REFINEMENT.out files (in both the censo and orca_cosmo folders)

## Customization

The level of theory used in the orca scripts can be changed by directly modifiying the template files in the templates folder, but it would be wise to test the
new input files independently of occult first. 

The level of theory used by CENSO can be changed by modifying the censo2rc.template file, see CENSO manual for more details. The thresholds can also be modified here,
which can help make the opimizations faster or slower, depending on desired results. 

Note: This is currently configured to run on a computer with 36 cores. If your computing nodes do not have 36 cores, you will need to change the core numbers
in the three .s scripts to match your system (line 7, occult_part1_orca.s, occult_part2_censo.s, occult_part3_), the nprocs line in the orca tempaltes (in the templates folder) and lines 48 and 49 in occult_part2_censo.s to match your number of cores/ntasks bceause CENSO has odd parallelization.

## Troubleshooting

First, check the .err and .out files for the main scripts, simple errors like missing variables from config.sh will be listed here.
If these files do not list an error, go into the latest job step (it goes nsolv -> goat -> censo -> orca_cosmo) and check the .out file from the orca or censo job
if problems persist with nsolv, goat, or censo, try testing the chemical systems with these softwares independently of the occult script, 
to see if the issue is specific to occult.

Known CENSO issue. If CENSO terminates with some kind of I/O error in the .out file, this is actually caused by the parallelization being set incorrectly and MPI 
failing subsequently. Make sure that the system has access to all 36 cores, or the error persists you could try setting lines 48 and 49 of occult_part2_censo.s to 1. 
This will substantially slow the calculation, but the error will likely be resolved. 
