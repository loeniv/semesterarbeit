function [cameraParams, imagesUsed, estimationErrors] = calibrate_camera(imageFileNames, squareSize)
%CALIBRATECAMERA Calibrates a camera using images of a checkerboard pattern.
%
%   [cameraParams, estimationErrors] = CALIBRATECAMERA(imageFileNames, squareSize)
%   calibrates a camera by estimating its intrinsic parameters based on detected
%   checkerboard corners in a set of images. The function outputs the camera
%   parameters and estimation errors.
%
%   Inputs:
%       imageFileNames - A cell array of strings or a string array, where each
%                        element is the path to an image file containing a
%                        checkerboard pattern viewable by the camera.
%       squareSize - A scalar value specifying the size of each square in the
%                    checkerboard pattern, typically in millimeters or inches.
%
%   Outputs:
%       cameraParams - A cameraParameters object containing the estimated camera
%                      intrinsic parameters, including focal length, principal point,
%                      and radial distortion coefficients.
%       imagesUsed - A array indicating which images have been used to estimate the 
%                    camera parameters.
%       estimationErrors - Standard errors of estimated parameters, returned as a 
%                          cameraCalibrationErrors object or a stereoCalibrationErrors 
%                          object.
%
%   Example:
%       imageFileNames = {'image1.jpg', 'image2.jpg', ...};
%       squareSize = 25; % in millimeters
%       [cameraParams, estimationErrors] = calibrateCamera(imageFileNames, squareSize);
%
%   Note:
%       Ensure that the checkerboard pattern is fully visible in all images and
%       that the images cover a wide range of views. Good practice involves capturing
%       images from different angles and distances.

    % Detect checkerboard corners in the images
    [imagePoints, boardSize] = detectCheckerboardPoints(imageFileNames);
    
    % Generate world coordinates of the checkerboard corners
    worldPoints = generateCheckerboardPoints(boardSize, squareSize);
    % Center the world coordinates
    worldPoints = worldPoints - max(worldPoints) / 2;
    
    % Calibrate the camera
    I = imread(imageFileNames{1}); % Read the first image to get its size
    imageSize = [size(I, 1), size(I, 2)]; % [height, width]
    
    % Estimate camera parameters
    [cameraParams, imagesUsed, estimationErrors] = estimateCameraParameters(imagePoints, worldPoints, 'ImageSize', imageSize);
end
