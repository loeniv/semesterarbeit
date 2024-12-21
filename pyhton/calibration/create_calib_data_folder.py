import os
from datetime import datetime

def create_calib_data_folder(base_path):
    # Format the base directory name as "YearMonthDay-HourMinute-calib_data"
    dir_name = datetime.now().strftime("%Y%m%d-%H%M") + "-calib_data"
    base_dir_name = os.path.join(base_path, dir_name)
    
    # Define the folder structure to be created within the base directory
    folder_structure = [
        "left/laser/contour",
        "left/laser/distorted",
        "left/laser/masked",
        "left/laser/undistorted",
        "left/pattern/distorted",
        "left/pattern/undistorted",
        "right/laser/contour",
        "right/laser/distorted",
        "right/laser/masked",
        "right/laser/undistorted",
        "right/pattern/distorted",
        "right/pattern/undistorted",
    ]
    
    # Iterate through the folder structure and create each path
    for folder in folder_structure:
        # Combine the base directory name with the current folder path
        path = os.path.join(base_dir_name, folder)
        # Create the directory, including any necessary intermediate directories
        os.makedirs(path, exist_ok=True)
    
    print(f"Folder structure created under '{base_dir_name}'")
    return base_dir_name

# Example usage of the function to create a calibration data folder
if __name__ == "__main__":
    # Define the base directory where the calibration data folder will be created
    base_path = 'C:/Users/Robin/OneDrive/University/Master/Masterarbeit/Kalibrierdaten'
    # Create the calibration data folder
    create_calib_data_folder(base_path)
