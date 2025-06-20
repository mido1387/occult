import pandas as pd
import re
import glob
import sys
import os

# Step 1: Read the first file into a DataFrame
def read_first_file(filename):
    with open(filename, 'r') as f:
        lines = f.readlines()

    table_lines = []
    for line in lines:
        if 'Boltzmann averaged' in line:
            break
        if line.strip():
            table_lines.append(line)

    headers_line1 = table_lines[0].strip()
    headers_line2 = table_lines[1].strip()

    header1_parts = re.split(r'\s{2,}', headers_line1)
    header2_parts = re.split(r'\s{2,}', headers_line2)
    while len(header2_parts) < len(header1_parts):
        header2_parts.append('')

    headers = []
    for h1, h2 in zip(header1_parts, header2_parts):
        if h1.strip():
            headers.append(h1.strip())
        elif h2.strip():
            headers.append(h2.strip())
        else:
            headers.append('Unnamed')

    data = []
    for line in table_lines[2:]:
        parts = re.split(r'\s{2,}', line.strip())
        if len(parts) == len(headers):
            data.append(parts)

    df1 = pd.DataFrame(data, columns=headers)

    for col in df1.columns:
        if col != 'CONF#':
            df1[col] = pd.to_numeric(df1[col], errors='coerce')

    return df1

# Step 2: Read the second file into a DataFrame
def read_second_file(filename):
    return pd.read_csv(filename)

# Step 3: Merge and calculate weighted values
def merge_and_calculate(df1, df2, mode):
    df1.columns = df1.columns.str.strip()
    df2.columns = df2.columns.str.strip()

    df1['CONF_number'] = df1['CONF#'].astype(str).str.extract(r'(\d+)').astype(int)
    df2['CONF_number'] = df2['CONF#'].astype(str).str.extract(r'(\d+)').astype(int)

    merged = pd.merge(df1, df2, on='CONF_number', suffixes=('_df1', '_df2'))

    if mode == "COSMO":
        merged['weighted_Gsolv'] = merged['Boltzmann weight'] * merged['Gsolv (kcal/mol)']
        merged['weighted_Energy'] = merged['Boltzmann weight'] * merged['Single Point Energy (Eh)']
    elif mode == "GAS":
        merged['weighted_Energy'] = merged['Boltzmann weight'] * merged['Gas Phase Energy (Eh)']
    else:
        print("Unknown mode:", mode)
        sys.exit(1)

    return merged

# Step 4: Append summary row to result
def append_summary_row(df, mode):
    total_weight = df['Boltzmann weight'].sum()
    summary = {
        'CONF#_df1': 'TOTAL',
        'Boltzmann weight': total_weight,
    }

    if mode == "COSMO":
        gsolv_kcal = df['weighted_Gsolv'].sum() / total_weight
        gsolv_kJ = gsolv_kcal * 4.184
        summary['weighted_Gsolv'] = gsolv_kcal
        summary['Gsolv (kcal/mol)'] = f"{gsolv_kJ:.6f} kJ/mol (converted)"

    energy_hartree = df['weighted_Energy'].sum() / total_weight
    energy_kJmol = energy_hartree * 2625.5
    summary['weighted_Energy'] = energy_hartree
    summary['Energy (kJ/mol)'] = f"{energy_kJmol:.6f}"

    return pd.concat([df, pd.DataFrame([summary])], ignore_index=True)

# Step 5: Main script
if __name__ == "__main__":
    refinement_files = glob.glob("*3_REFINEMENT.out")
    if not refinement_files:
        print("ERROR: No file found ending with '3_REFINEMENT.out'")
        sys.exit(1)
    refinement_file = refinement_files[0]
    print(f"Using refinement file: {refinement_file}")

    data_file = None
    mode = None
    if os.path.exists("COSMO_Gsolv.csv"):
        data_file = "COSMO_Gsolv.csv"
        mode = "COSMO"
    elif os.path.exists("GAS_Energies.csv"):
        data_file = "GAS_Energies.csv"
        mode = "GAS"
    else:
        print("ERROR: Neither COSMO_Gsolv.csv nor GAS_Energies.csv found.")
        sys.exit(1)

    print(f"Using data file: {data_file} in mode: {mode}")

    df1 = read_first_file(refinement_file)
    df2 = read_second_file(data_file)

    result = merge_and_calculate(df1, df2, mode)

    # Print selected columns for review
    print_cols = ['CONF#_df1', 'Boltzmann weight']
    if mode == "COSMO":
        print_cols += ['Gsolv (kcal/mol)', 'weighted_Gsolv', 'Single Point Energy (Eh)']
    if 'weighted_Energy' in result.columns:
        print_cols.append('weighted_Energy')

    print(result[print_cols])

    # Add summary row to CSV
    result_with_summary = append_summary_row(result, mode)
    result_with_summary.to_csv('weighted_results.csv', index=False)

    # Print final result
    if mode == "COSMO":
        print(f"\nFinal weighted Gsolv: {result_with_summary.loc[result_with_summary['CONF#_df1'] == 'TOTAL', 'weighted_Gsolv'].values[0]:.6f} kcal/mol")
        print(f"Final weighted Gsolv: {float(result_with_summary.loc[result_with_summary['CONF#_df1'] == 'TOTAL', 'Gsolv (kcal/mol)'].values[0].split()[0]):.6f} kJ/mol")

    final_energy = float(result_with_summary.loc[result_with_summary['CONF#_df1'] == 'TOTAL', 'weighted_Energy'].values[0])
    final_kjmol = float(result_with_summary.loc[result_with_summary['CONF#_df1'] == 'TOTAL', 'Energy (kJ/mol)'].values[0])
    print(f"Final weighted Energy: {final_energy:.8f} Hartree")
    print(f"Final weighted Energy: {final_kjmol:.6f} kJ/mol")
