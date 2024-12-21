import halcon as ha  # Import the HALCON library for advanced image processing
import math  # Import the math library for mathematical operations
import cv2 as cv  # Import OpenCV for image handling and visualization
import os # Import the os library for file and directory operations
import glob # Import the glob library for file and directory operations
import csv # Import the csv library for reading and writing CSV files

# Function to extract points along lines within a specified region of interest from an image
def extractLinePoints(path: str, roi: list, max_line_width: int, contrast_low: int, contrast_high: int, light_dark: str = 'light') -> list:
    """
    Extracts points along lines within a specified region of interest from an image.

    Parameters:
        path (str): Path to the image file.
        roi (list): A list specifying the region of interest in the format [row1, col1, row2, col2].
        max_line_width (int): Maximum expected line width in pixels.
        contrast_low (int): Lower threshold for line contrast.
        contrast_high (int): Upper threshold for line contrast.
        light_dark (str, optional): Specifies if lines are lighter ('light') or darker ('dark') than the background. Defaults to 'light'.

    Returns:
        list: A list containing two lists, the first for x-coordinates and the second for y-coordinates of the line points.
    """
    # Calculate necessary parameters for line extraction based on inputs
    half_width = max_line_width / 2.0
    sigma = half_width / math.sqrt(3.0)
    help = -2.0 * half_width / (math.sqrt(6.283185307178) * math.pow(sigma,3.0)) * math.exp(-0.5 * pow(half_width / sigma,2.0))
    high = math.fabs(contrast_high * help)
    low = math.fabs(contrast_low * help)

    # Read the image and crop to the specified region of interest
    img = ha.read_image(path)
    img_roi = ha.crop_rectangle1(img, roi[0], roi[1], roi[2], roi[3])

    # Parameters for line extraction
    extract_width = "true"
    line_model = 'bar-shaped'
    complete_junctions = 'false'
    
    # Extract lines within the ROI based on specified parameters
    lines = ha.lines_gauss(img_roi, sigma, low, high, light_dark, extract_width, line_model, complete_junctions)

    # Select lines based on their length
    longLines = ha.select_contours_xld(lines, 'contour_length', 15, 5000, 0, 0)

    # Initialize lists to store coordinates of extracted line points
    x = []
    y  = []

    # Iterate over extracted lines to collect their point coordinates
    for i in range(len(longLines)):
        new_points = ha.get_contour_xld(longLines[i])
        x.extend(new_points[0])
        y.extend(new_points[1])

    # Adjust points' coordinates based on the ROI's offset
    row = [x[i] + roi[0] for i in range(len(x))]
    col = [y[i] + roi[1] for i in range(len(y))]
    points = [row, col]

    return points

# Function to find pictures in a folder and its subfolders
def find_pictures_in_folder(folder_path):
    # Define the picture file extensions to search for
    picture_extensions = ['*.jpg', '*.jpeg', '*.png', '*.gif', '*.bmp', '*.tiff', '*.webp']
    picture_paths = []

    # Search for pictures in the specified folder and its subfolders
    for extension in picture_extensions:
        picture_paths.extend(glob.glob(os.path.join(folder_path, '**', extension), recursive=True))

    # Return the total number of pictures found and their paths
    return len(picture_paths), picture_paths


# Example usage of the function to extract line points from an image
if __name__ == "__main__":
    # Configuration for image path, region of interest, line width, and contrast
    path_source = 'C:/Users/Robin/OneDrive/University/Master/Masterarbeit/Scandaten/V2/20240319-2023-scan_data/masked/'
    path_save = 'C:/Users/Robin/OneDrive/University/Master/Masterarbeit/Scandaten/V2/20240319-2023-scan_data/contour/'
    roi = [0, 0, 2592, 4608]  # ROI in [row1, col1, row2, col2] format
    max_line_width = 50  # Max line width in pixels
    contrast_low = 3
    contrast_high = 10  # Line contrast
    
    # Find pictures in the specified folder and its subfolders
    n_pictures, picture_paths = find_pictures_in_folder(path_source)
    print(f'Found {n_pictures} pictures in the specified folder and its subfolders.')
    
    for p in picture_paths:
        # Extract line points from the image
        points = extractLinePoints(p, roi, max_line_width, contrast_low, contrast_high)
        y = points[0]
        x = points[1]
        # Save the extracted points to a CSV file
        filename = p.split('\\')[-1].split('_')[0] + '_contour.csv'
        destination = os.path.join(path_save, filename)
        print(destination)
        with open(filename, mode='w', newline='') as file:
            writer = csv.writer(file)
            
            # Write each row to the CSV file
            for x, y in zip(x, y):
                writer.writerow([x,y])

    

    # Visualize extracted points using OpenCV
    #img_cv = cv.imread(path)
    #for i in range(len(points[0])):
    #    px = int(points[0][i])
    #    py = int(points[1][i])
    #    img_cv = cv.circle(img_cv, (py, px), 1, (0, 0, 255), 1)

    #img_scaled = cv.resize(img_cv, (1500, 1500))  
    #cv.imshow('img', img_scaled)
    #cv.waitKey(0)
