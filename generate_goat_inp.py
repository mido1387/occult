from pathlib import Path
import argparse

def extract_coordinates(xyz_path, nsolv=0):
    """Extracts coordinates, labeling fragments if solvent molecules are present."""
    with open(xyz_path, 'r') as f:
        lines = f.readlines()
    coord_lines = lines[2:]  # skip first two lines

    if nsolv == 0:
        return coord_lines  # no fragment labeling needed

    total_atoms = len(coord_lines)
    n_water_atoms = nsolv * 3
    n_main_atoms = total_atoms - n_water_atoms

    labeled_coords = []

    # Main molecule: fragment 1
    for line in coord_lines[:n_main_atoms]:
        parts = line.strip().split()
        labeled_coords.append(f"{parts[0]}(1) {' '.join(parts[1:])}\n")

    # Waters: fragments 2+
    for i in range(nsolv):
        frag_num = i + 2
        start = n_main_atoms + i * 3
        for line in coord_lines[start:start + 3]:
            parts = line.strip().split()
            labeled_coords.append(f"{parts[0]}({frag_num}) {' '.join(parts[1:])}\n")

    return labeled_coords

def insert_coordinates_and_variables(template_path, coordinates, output_path, charge, spin, solvent):
    """Inserts coordinates and replaces placeholders in the template file."""
    with open(template_path, 'r') as f:
        template = f.read()

    coord_block = ''.join(coordinates).strip()
    content = template.replace("PASTE COORDINATES HERE", coord_block)
    # NEW: Added solvent replacement
    content = content.replace("{charge}", str(charge)).replace("{spin}", str(spin)).replace("{solvent}", solvent)

    # Ensure parent directory exists
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with open(output_path, 'w') as f:
        f.write(content)

    print(f"GOAT input file written to: {output_path}")

if __name__ == "__main__":
    # --- Argument Parsing ---
    parser = argparse.ArgumentParser(description="Insert coordinates and variables into goat.inp template.")
    parser.add_argument("xyz_file", help="Path to the .solvator.xyz file")
    parser.add_argument("charge", type=int, help="Molecular charge")
    parser.add_argument("spin", type=int, help="Molecular spin multiplicity")
    # NEW: Added solvent argument
    parser.add_argument("solvent", type=str, help="Solvent name for the calculation")
    parser.add_argument(
        "--template",
        default=Path(__file__).resolve().parent / "templates" / "goat.inp",
        help="Path to the GOAT template file (default: templates/goat.inp relative to script)"
    )
    parser.add_argument(
        "--nsolv",
        type=int,
        default=0,
        help="Number of water molecules added by solvator"
    )

    args = parser.parse_args()

    # --- Script Execution ---
    coords = extract_coordinates(args.xyz_file, args.nsolv)
    prefix = Path(args.xyz_file).stem.replace(".solvator", "")

    output_dir = Path("goat")
    output_file = output_dir / f"{prefix}.goat.inp"

    # NEW: Passed the solvent argument to the function
    insert_coordinates_and_variables(args.template, coords, output_file, args.charge, args.spin, args.solvent)