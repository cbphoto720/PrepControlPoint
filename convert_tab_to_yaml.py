import yaml
import csv

def convert_tab_to_yaml(input_file, output_file):
    data_list = []

    try:
        print(f"Reading from: {input_file}")  # Debugging output

        with open(input_file, 'r', newline='', encoding='utf-8') as file:
            reader = csv.DictReader(file, delimiter='\t')

            for row in reader:
                camera_data = {
                    'CamSN': row['CamSN'],
                    'CamNickname': row['CamNickname'],
                    'DateofGCP': row['DateofGCP'],
                    'Intrinsics': {
                        'Skew': row['ac'],
                        'PrincipalPoint_U': row['c0U'],
                        'PrincipalPoint_V': row['c0V'],
                        'FocalLength_X': row['fx'],
                        'FocalLength_Y': row['fy'],
                        'RadialDistortion_1': row['d1'],
                        'RadialDistortion_2': row['d2'],
                        'RadialDistortion_3': row['d3'],
                        'TangentialDistortion_1': row['t1'],
                        'TangentialDistortion_2': row['t2'],
                        'ImageSize_U': row['NU'],
                        'ImageSize_V': row['NV']
                    },
                    'Position': {
                        'Northings': row['Northings'] if row['Northings'] else None,
                        'Eastings': row['Eastings'] if row['Eastings'] else None,
                        'Height': row['Height'] if row['Height'] else None,
                        'UTMzone': row['UTMzone'] if row['UTMzone'] else None,
                        'pitch': row['pitch'] if row['pitch'] else None,
                        'roll': row['roll'] if row['roll'] else None,
                        'azimuth': row['azimuth'] if row['azimuth'] else None,
                    },
                    'Local Coordinate System': {
                        'originUTMnorthing': row['originUTMnorthing'] if row['originUTMnorthing'] else None,
                        'originUTMeasting': row['originUTMeasting'] if row['originUTMeasting'] else None,
                        'theta': row['theta'] if row['theta'] else None
                    }
                }

                data_list.append(camera_data)

        print(f"Writing to: {output_file}")

        with open(output_file, 'w', encoding='utf-8') as file:
            yaml.dump(data_list, file, default_flow_style=False, sort_keys=False)

        print("Conversion successful!")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    import sys
    if len(sys.argv) != 3:
        print("Usage: python convert_tab_to_yaml.py <input_file> <output_file>")
    else:
        convert_tab_to_yaml(sys.argv[1], sys.argv[2])
