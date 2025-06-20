For Nicole, TO BE UPDATED FOR RELEASE!!!!

OCCULT Set up instructions:
Make two new directories, one inside your MyScripts called OCCULT, and one inside your pKa_project folder called OCCULT. One will be where the code is stored the other is where the runs will take place.
Extract the contents of the zipped folder I sent into the MyScripts OCCULT folder
Edit occult_v2.s, change line 18 to your conda env (sci) and save it
Edit wrapper.sh, update the two file paths (lines 18 and 19), which should be, make sure that's where the code actually is. "OCCULT_DIR="/beegfs/scratch/nfoss/MyScripts/OCCULT"
"TEMPLATES_DIR="/beegfs/scratch/nfoss/MyScripts/OCCULT/Templates"

Occult use instructions
Make some folder within your pKa_project/OCCULT/ directory. I think its best to make a unique folder for every job, so maybe pKa_project/OCCULT/FBSA/Acid or something.
Copy wrapper.sh and the .xyz file for the chemical into this folder
In putty, cd to this new folder, and type "bash wrapper.sh YOURFILENAME.xyz" putting in the correct file name. You can then refresh the folder, there should now be a lot of stuff in there. 
Edit occult_v2.s, which should now be in the folder, and update lines 25-28. Spin should be 1 and nsolv should be 0, but the .xyz and the charge will change. 
Now just sbatch occult_v2.s