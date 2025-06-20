import os
import csv
import re

# Output CSV file
output_file = "COSMO_Gsolv.csv"

# Prepare list to collect data
data = []

# Walk through all subdirectories
for root, dirs, files in os.walk("."):
    for file in files:
        if file.endswith("COSMO.out"):
            file_path = os.path.join(root, file)
            gsolv = ""
            sp_energy = ""
            conf_number = ""

            with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                for line in f:
                    # Extract Gsolv in kcal/mol
                    if "Free energy of solvation (dGsolv)" in line:
                        parts = line.split()
                        try:
                            gsolv = parts[-2]  # kcal/mol value
                        except IndexError:
                            print(f"Warning: Could not parse Gsolv line in {file_path}")

                    # Extract single-point energy
                    if "FINAL SINGLE POINT ENERGY (Solute-CPCM)" in line:
                        parts = line.strip().split()
                        try:
                            sp_energy = parts[-1]  # final number on line
                        except IndexError:
                            print(f"Warning: Could not parse SP energy line in {file_path}")

                # Extract CONF# from filename using regex
                match = re.search(r'CONF(\d+)', file)
                conf_number = match.group(1) if match else ""

                # Only add if at least Gsolv or SP energy found
                if gsolv or sp_energy:
                    data.append([file, gsolv, conf_number, sp_energy])

# Sort data by CONF# (numerically)
def conf_sort_key(item):
    try:
        return int(item[2])  # CONF# column
    except ValueError:
        return float('inf')

data.sort(key=conf_sort_key)

# Write results to CSV
with open(output_file, "w", newline="") as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(["Filename", "Gsolv (kcal/mol)", "CONF#", "Single Point Energy (Eh)"])
    writer.writerows(data)

print(f"Finished! Data written to {output_file}.")
