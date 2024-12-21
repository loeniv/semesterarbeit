function points = extract_line_points(imagePath, roi, maxLineWidth, contrastLow, contrastHigh)
%EXTRACT_LINE_POINTS Extracts line points from an image using Python.
%   This function interfaces with a Python script to extract points forming lines within an image.
%   It allows for the specification of a region of interest (ROI), maximum line width, and contrast thresholds.
%   The Python script is expected to return coordinates of points in the detected lines.
%
%   Inputs:
%       imagePath - A string specifying the path to the image file.
%       roi - A four-element vector [x, y, width, height] defining the region of interest in the image.
%       maxLineWidth - A scalar specifying the maximum width of the lines to be detected.
%       contrastLow - A scalar defining the lower threshold for contrast filtering.
%       contrastHigh - A scalar defining the upper threshold for contrast filtering.
%
%   Output:
%       points - An Nx2 array of [x, y] coordinates of points in the detected lines.

    % Set Python environment
    pyenv(Version="C:\Users\Robin\anaconda3\envs\Laser\python.exe");
    
    % Path to the Python file for line extraction
    pathPyFile = "C:\Users\Robin\OneDrive\University\Master\Masterarbeit\IndiPrint\scanner\laser\matlab\matlab_line_extraction_binding.py";
    
    % Run the Python script and pass the parameters
    pyPoints = pyrunfile(pathPyFile, "points", ...
                         path=imagePath, ...
                         roi=roi, ...
                         max_line_width=maxLineWidth, ...
                         contrast_low=contrastLow, ...
                         contrast_high=contrastHigh, ...
                         light_dark='light');
    
    % Convert Python list to MATLAB cell arrays
    cellPointsX = cell(pyPoints{2});
    cellPointsY = cell(pyPoints{1});
    
    % Convert cells to MATLAB arrays
    pointsX = cellfun(@double, cellPointsX);
    pointsY = cellfun(@double, cellPointsY);
    
    % Combine x and y coordinates
    points = [pointsX', pointsY'];
end
