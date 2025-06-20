from pathlib import Path
import argparse

def label_fragments(xyz_file, nsolv, output_file=None):
    with open(xyz_file, 'r') as f:
        lines = f.readlines()

    atom_count = int(lines[0].strip())
    comment_line = lines[1]
    coord_lines = lines[2:]

    if len(coord_lines) != atom_count:
        raise ValueError("Atom count mismatch in .xyz file.")

    if nsolv == 0:
        print("NSOLV=0: no fragment labeling needed.")
        return xyz_file  # Return original file path (no modification)

    n_water_atoms = nsolv * 3
    n_main_atoms = atom_count - n_water_atoms

    labeled_lines = []

    # Fragment 1: original molecule
    for line in coord_lines[:n_main_atoms]:
        parts = line.strip().split()
        labeled_lines.append(f"{parts[0]}(1) {' '.join(parts[1:])}\n")

    # Fragments 2+: waters
    for i in range(nsolv):
        frag_num = i + 2
        for j in range(3):  # O, H, H
            idx = n_main_atoms + i * 3 + j
            parts = coord_lines[idx].strip().split()
            labeled_lines.append(f"{parts[0]}({frag_num}) {' '.join(parts[1:])}\n")

    # Prepare output path
    output_path = (
        Path(output_file) if output_file
        else Path(xyz_file).with_name(Path(xyz_file).stem + "_fragged.xyz")
    )

    with open(output_path, 'w') as f:
        f.write(f"{atom_count}\n")
        f.write(comment_line)
        f.writelines(labeled_lines)

    print(f"Fragment-labeled file written to: {output_path}")
    return output_path


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Label fragments in .xyz file using NSOLV.")
    parser.add_argument("xyz_file", help="Path to input .xyz file")
    parser.add_argument("nsolv", type=int, help="Number of water molecules")
    parser.add_argument("--output", help="Path to write fragment-labeled .xyz file")

    args = parser.parse_args()
    label_fragments(args.xyz_file, args.nsolv, args.output)
