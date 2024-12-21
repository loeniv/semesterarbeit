clear; clc;
% Path
pathCalibration = "C:\Users\Robin\OneDrive\University\Master\Masterarbeit\Experimente\2024-03-30-RS-Genauigkeit-Dental\tooth\calib\";
pathScan = "C:\Users\Robin\OneDrive\University\Master\Masterarbeit\Experimente\2024-03-30-RS-Genauigkeit-Dental\tooth\scan\";
pathDistorted = strcat(pathScan, "left\" ,"distorted\");
pathUndistorted = strcat(pathScan, "left\" ,"undistorted\");
pathMasked = strcat(pathScan, "left\" ,"masked\");

%% STEP 1: UNDISTORT PICTURES
% Load data from camera calibration
load(strcat(pathCalibration,"distortedCameraParams.mat"));
load(strcat(pathCalibration,"calibrationPoses.mat"));

disp('Started camera calibration.');

% Reading images from the specified path
disp('Reading images from path...');
distortedImages = imageDatastore(pathDistorted);
distortedImageFileNames = distortedImages.Files;

% Undistort images
disp('Undistort images...')
tUndistort = undistort_images(distortedImages, distortedCameraParams, pathUndistorted);

%% STEP 2: MASK IMAGES
% Filter/mask laser images
disp('Masking laser images...')
undistortedImages = imageDatastore(pathUndistorted);
tMask = mask_images(undistortedImages, pathMasked);

%% STEP 3: RECONSTRUCT OBJECT
% Load calibration data
load(strcat(pathCalibration,"calibrationPoses.mat"));
load(strcat(pathCalibration,"optimizedExtrinsics.mat"));
load(strcat(pathCalibration,"planeParams.mat"));

% Load images
maskedImages = imageDatastore(pathMasked);
maskedImageFileNames = maskedImages.Files;
nPoses = length(maskedImageFileNames);

% Initialize variables
load(strcat(pathScan,"angles.mat"))
K = calibrationPoses(1).intrinsics.K;
camera3DPoints = [];
tReconstruct = zeros(nPoses, 1);

% Settings for laser line detection
I = imread(maskedImageFileNames{1}); % Read the first image to get its size
resolution = size(I, 1); % [height = width]
max_line_width = 40 * resolution / 2592; % 40 for 2592x2592
contrast_high = 10;
contrast_low = 0.3 * contrast_high;
roi = [0, 0, resolution, resolution];

% Reconstruct object by triangulation
textprogressbar('Reconstructing object: ');

for i = 1:nPoses
    tic
    % Find laser line
    points = extract_line_points(maskedImageFileNames(i), roi, max_line_width, contrast_low, contrast_high);
    nPoints = length(points);
    poseCamera3DPoints = zeros(nPoints, 3);

    % Iterate over all points and triangulate
    for j = 1:nPoints
        imagePoint = points(j, :)';
        p = triangulate_point(imagePoint, planeParams, K);
        poseCamera3DPoints(j,:) = p';
    end
    % Transform measured points back to reference frame
    theta1 = angles(i,1);
    theta2 = angles(i,2);
    T = var2tform(w1, theta1, w2, theta2, q);
    refCamera3DPoints = (T \ [poseCamera3DPoints, ones(nPoints,1)]')';

    % Transform measured points in camera reference frame back to world
    % coordinates
    camera3DPoints = [camera3DPoints; refCamera3DPoints(:,1:3)];

    % Show progress
    textprogressbar(100 * i / nPoses);

    % Save time
    tReconstruct(i) = toc;
end

% Transform all camera points in refernce frame to world coordinate system
world3DPoints = (T_CW_ref \ [camera3DPoints, ones(length(camera3DPoints),1)]')';
world3DPoints = world3DPoints(:,1:3);
textprogressbar('done');

% Save world points raw and as point cloud object
save(strcat(pathScan, "object.mat"), "world3DPoints");
ptCloud = pointCloud(world3DPoints);
pcwrite(ptCloud,strcat(pathScan, "object.ply"))

% Save process times
load(strcat(pathScan, "captureTime.mat")); % This includes tCapture only at this point
save(strcat(pathScan, "scanTimes.mat"), "tCapture", "tUndistort", "tMask", "tReconstruct");

%% Plot result
figure
pcshow(ptCloud);
axis equal