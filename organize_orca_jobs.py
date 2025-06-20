import os
import glob
import shutil
import re

def main():
    cwd = os.getcwd()

    # Find all files that end with _COSMO.inp
    inp_files = glob.glob("*_COSMO.inp")

    if not inp_files:
        print("No *_COSMO.inp files found.")
        return

    for inp_file in inp_files:
        # Use regex to find CONF# in the middle of the filename
        match = re.search(r"(CONF\d+)_COSMO\.inp$", inp_file)
        if not match:
            print(f"Skipping unrecognized file name: {inp_file}")
            continue

        conf_id = match.group(1)  # e.g., "CONF1"
        xyz_file = inp_file.replace(".inp", ".xyz")

        if not os.path.exists(xyz_file):
            print(f"Missing XYZ file for {conf_id}, skipping.")
            continue

        # Create CONF# directory
        conf_dir = os.path.join(cwd, conf_id)
        os.makedirs(conf_dir, exist_ok=True)

        # Move both files into the new directory
        shutil.move(inp_file, os.path.join(conf_dir, inp_file))
        shutil.move(xyz_file, os.path.join(conf_dir, xyz_file))
        print(f"Moved: {inp_file}, {xyz_file} -> {conf_dir}/")

if __name__ == "__main__":
    main()
