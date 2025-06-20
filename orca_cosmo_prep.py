import os
import glob
import shutil
import argparse


def read_template(file_path):
    try:
        with open(file_path, 'r') as file:
            return file.read()
    except FileNotFoundError:
        print(f"The file {file_path} was not found.")
        return None


def extract_geometry(xyz_file):
    try:
        with open(xyz_file, 'r') as file:
            lines = file.readlines()[2:]  # Extract from line 3 onward
        return ''.join(lines)
    except Exception as e:
        print(f"Failed to extract geometry from {xyz_file}: {e}")
        return None


def create_xyz_copy(xyz_file, suffix):
    try:
        filename = os.path.splitext(os.path.basename(xyz_file))[0]
        new_xyz_file_name = os.path.join(os.path.dirname(xyz_file), f"{filename}_{suffix}.xyz")
        shutil.copyfile(xyz_file, new_xyz_file_name)
        print(f"XYZ copy created: {new_xyz_file_name}")
        return new_xyz_file_name
    except Exception as e:
        print(f"Failed to create xyz copy for {xyz_file}: {e}")
        return None


def create_template_copy(template_content, xyz_file, copied_xyz_file, charge, spin):
    try:
        new_xyz_filename = os.path.splitext(os.path.basename(copied_xyz_file))[0]
        geometry_data = extract_geometry(xyz_file)
        if geometry_data is None:
            return

        modified_content = template_content
        modified_content = modified_content.replace("{template}", new_xyz_filename)
        modified_content = modified_content.replace("{geometry}", geometry_data)
        modified_content = modified_content.replace("{charge}", str(charge))
        modified_content = modified_content.replace("{spin}", str(spin))

        new_template_file_name = os.path.join(os.path.dirname(copied_xyz_file), f"{new_xyz_filename}.inp")

        with open(new_template_file_name, 'w') as new_file:
            new_file.write(modified_content)

        print(f"Template copy created: {new_template_file_name}")
    except Exception as e:
        print(f"Failed to create template copy for {xyz_file}: {e}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Prepare ORCA input files from xyz geometries.")
    parser.add_argument("--directory", default=".", help="Directory containing CONF xyz files")
    parser.add_argument("--charge", type=int, required=True, help="Molecular charge")
    parser.add_argument("--spin", type=int, required=True, help="Spin multiplicity")
    args = parser.parse_args()

    suffix = "COSMO"
    template_path = os.path.join(os.path.dirname(__file__), "templates", "cosmors_template.inp")
    template = read_template(template_path)

    if template:
        xyz_files = glob.glob(os.path.join(args.directory, '*CONF*.xyz'))
        if not xyz_files:
            print("No *CONF*.xyz files found in the directory.")
        else:
            for xyz_file in xyz_files:
                copied_xyz_file = create_xyz_copy(xyz_file, suffix)
                if copied_xyz_file:
                    create_template_copy(template, xyz_file, copied_xyz_file, args.charge, args.spin)
