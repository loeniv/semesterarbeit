function tUndistort = undistort_images(images, cameraParams, path)
% UNDISTORT_IMAGES Undistorts a series of images using specified camera parameters.
% 
% Syntax: UNDISTORT_IMAGES(images, cameraParams, path)
%
% Inputs:
%    images - A structure containing the file paths of the images to be undistorted. 
%             This is often obtained from the ImageDatastore function.
%    cameraParams - An object containing the camera parameters returned by the
%                   estimateCameraParameters function or the cameraCalibrator app.
%    path - A string specifying the folder path where the undistorted images will be saved.
%           The path should end with a slash (e.g., '/path/to/folder/').
%
% Outputs:
%    tUndistort - An array containing undistortion times for each image
%
% Example: 
%    images = imageDatastore('path/to/images');
%    load('cameraparams.mat'); % Assuming cameraparams is saved in this file
%    undistort_images(images, cameraparams, 'path/to/save/undistorted/');
%
% Other m-files required: textprogressbar
% Subfunctions: none
% MAT-files required: none
%
% See also: imageDatastore, estimateCameraParameters, cameraCalibrator, textprogressbar

    nPoses = length(images.Files); % Number of poses/images
    tUndistort = zeros(nPoses, 1);

    textprogressbar('Undistorting images: ');

    for i = 1:nPoses
        tic
        imgUndistorted = undistortImage(readimage(images, i), cameraParams); % Undistort each image        
        num = i - 1;
        numStr = get_number_string(nPoses, num);
        imwrite(imgUndistorted, strcat(path, numStr, "_undist.png")); % Save undistorted image
        textprogressbar(100 * i / nPoses);
        tUndistort(i) = toc;
    end

    textprogressbar('done');
end
