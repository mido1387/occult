Do you want to use this version of occult? here are the quick instructions:

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