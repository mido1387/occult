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
SLURM 
XTB 
Python 3 environment with: CENSO, openbabel and pandas installed

Update eveything in the config.sh file to match your ORCA/XTB/Conda environment (with CENSO installed)
If you want to use the wrapper, update the two filepaths OCCULT_DIR and TEMPLATES_DIR to wherever the directory you put these scripts into

Normal use: place the wrapper.sh and your .xyz file (doesn't need to be optimized) in the same folder and:
bash wrapper.sh yourmolecule.xyz

It will then prompt you to edit a few lines in occult_part1_orca.s, CHARGE, SPIN, and NSOLV, where nsolv is the number
of explicit waters you would like to add (can be changed to another solvent by editing the nsolv template) and SOLVENT, 
where you pick the solvent (make sure it is supportde by ALPB and openCOSMO by checking their webpages)

sbatch occult_part1_orca.s, and it once that is done it will automatically run the
other two scripts. 

If you have a orca_cosmo folder with a weighted_results.csv in it, then the job was successful, if not, start by looking in the censo folder for any errors.

The final optimized geometries and energies are found it the 3_REFINEMENT.xyz and 3_REFINEMENT.out files (in both the censo and orca_cosmo folders)
