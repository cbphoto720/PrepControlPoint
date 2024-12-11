from PIL import Image, TiffImagePlugin

def modify_metadata(input_path, output_path, new_date):
    try:
        # Open the image
        img = Image.open(input_path)

        # Check the file format
        file_format = img.format.upper()

        if file_format == 'JPEG':
            # Handle JPEG metadata
            exif_data = img.getexif()

            # Update DateTimeOriginal (36867) and DateTime (306) tags
            exif_data[36867] = new_date  # DateTimeOriginal
            exif_data[306] = new_date    # DateTime

            # Save with updated EXIF
            img.save(output_path, exif=exif_data)
            print(f"Metadata for JPEG updated and saved to {output_path}")

        elif file_format == 'TIFF':
            # Handle TIFF metadata
            tiff_metadata = img.tag_v2

            # Update DateTime (306) tag
            tiff_metadata[306] = new_date

            # Save with updated TIFF metadata
            img.save(output_path, tiffinfo=tiff_metadata)
            print(f"Metadata for TIFF updated and saved to {output_path}")

        else:
            print("Unsupported file format. Please use JPEG or TIFF.")
    except Exception as e:
        print(f"Error: {e}")

# Allow script execution via command-line arguments
if __name__ == "__main__":
    import sys
    if len(sys.argv) < 4:
        print("Usage: python modify_metadata.py <input_path> <output_path> <new_date>")
    else:
        input_path = sys.argv[1]
        output_path = sys.argv[2]
        new_date = sys.argv[3]
        modify_metadata(input_path, output_path, new_date)
