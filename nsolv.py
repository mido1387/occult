import os
import sys
from pathlib import Path

def read_template(template_path):
    """Reads the content of a template file."""
    try:
        with open(template_path, 'r') as f:
            return f.read()
    except FileNotFoundError:
        print(f"Template file not found: {template_path}")
        sys.exit(1)

def extract_coordinates(xyz_path):
    """Extracts atomic coordinates from the third line onwards in an xyz file."""
    try:
        with open(xyz_path, 'r') as f:
            lines = f.readlines()
        return ''.join(lines[2:])  # Skip first two lines (atom count and comment)
    except Exception as e:
        print(f"Error reading XYZ file: {e}")
        sys.exit(1)

def create_inp_file(template, coords, basename, nsolv, charge, spin, solvent):
    """Creates a new input file by replacing placeholders in the template."""
    content = template.replace("{coordinates}", coords)
    content = content.replace("{nsolv}", str(nsolv))
    content = content.replace("{charge}", str(charge))
    content = content.replace("{spin}", str(spin))
    # NEW: Added solvent replacement
    content = content.replace("{solvent}", solvent)

    output_dir = Path("nsolv")
    output_dir.mkdir(exist_ok=True)

    output_file = output_dir / f"{basename}_nsolv_{nsolv}.inp"
    with open(output_file, 'w') as f:
        f.write(content)

    print(f"Created ORCA input file: {output_file}")
    return output_file

if __name__ == "__main__":
    # --- Argument Parsing ---
    # NEW: Updated argument count check
    if len(sys.argv) != 6:
        # NEW: Updated usage message
        print("Usage: python nsolv.py <nsolv> <xyz_file> <charge> <spin> <solvent>")
        sys.exit(1)

    nsolv = sys.argv[1]
    xyz_file = sys.argv[2]
    charge = sys.argv[3]
    spin = sys.argv[4]
    # NEW: Added solvent argument
    solvent = sys.argv[5]

    xyz_path = Path(xyz_file)
    if not xyz_path.exists():
        print(f"XYZ file not found: {xyz_file}")
        sys.exit(1)

    # --- Script Execution ---
    # Locate template relative to this script
    script_dir = Path(__file__).resolve().parent
    template_path = script_dir / "templates" / "nsolv_template.inp"
    template = read_template(template_path)
    coords = extract_coordinates(xyz_path)
    basename = xyz_path.stem

    # NEW: Passed the solvent argument to the function
    create_inp_file(template, coords, basename, nsolv, charge, spin, solvent)