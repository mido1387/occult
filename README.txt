ORCA CENSO Conformational sampling ULTimate (OCCULT) workflow

This package uses slurm scripts to automatically:
1) Preoptimize an input .xyz geometry
2) Add explicit solvent molecules (if desired) with ORCA's SOLVATOR (driven by XTB)
3) Generate a massive ensemble of conformers with the Global Optimizer Algorithm (GOAT) in ORCA
4) Sort and optimize the ensemble down to the best conformers, rank them with a Boltzman distribution using Command line Ensemble-Sorting (CENSO)
  4a) Screen conformers with XTB (can be changed by user)
  4b) Screen remaining confomers with r2scan-3c (can be changed by user)
  4c) optimize best confomers with wB97x-v/def2-TZVP (can be changed by user)
5) Calculate solvation free energy of best conformers using openCOSMO-RS

From just an input .xyz you now have a list of optimized conformers as well as a solvation energy, with explicit solvent included if desired.

Do you want to use this version of occult? here are the quick instructions:

Requirements:
ORCA 6.0.0+
SLURM managed computing cluster
XTB 
CENSO
Python 3 environment with: Openbabel and pandas installed

Update the following: update the paths to the correct orca and xtb paths in the 'censo2rc' file, 

Normal use, place the wrapper.sh and your .xyz file (doesn't need to be optimized) in the same folder and:
bash wrapper.sh yourmolecule.xyz

It will then prompt you to edit a few lines in occult_part1_orca.s, CHARGE, SPIN, and NSOLV, where nsolv is the number
of explicit waters you would like to add (can be changed to another solvent by editing the nsolv template)

sbatch occult_part1_orca.s, and it once that is done it will automatically run the
other two scripts. 

If you have a orca_cosmo folder with a weighted_results.csv in it, then the job was successful, if not, start by looking in the censo folder for any errors.

To set up you need to change:
conda activate obabel in the occult_part1_orca.s to match your python environment where CENSO is installed (mine was obabel)

Make sure the paths to orca and xtb are correct for your system

Update the paths in the wrapper to tell it where the occult and templates folders are


Update file paths in censo2rc file at the bottom as well
