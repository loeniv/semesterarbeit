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

points = extractLinePoints(path, roi, max_line_width, contrast_low, contrast_high, light_dark) 