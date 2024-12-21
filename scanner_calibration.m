%% SETTINGS AND DESCRIPTION
clear; clc;
% Path
path = "C:\Users\Robin\OneDrive\University\Master\Masterarbeit\Experimente\2024-03-25-RS-Scangeschwindigkeit\2592x2592\calib\";
pathDistortedCheckerboard = strcat(path, "left\" ,"pattern\distorted\");
pathUndistortedCheckerboard = strcat(path, "left\" ,"pattern\undistorted\");
pathDistortedLaser = strcat(path, "left\" ,"laser\distorted\");
pathUndistortedLaser = strcat(path, "left\" ,"laser\undistorted\");
pathMaskedLaser = strcat(path, "left\" ,"laser\masked\");
pathAngles = strcat(path, "angles.csv");

%% 1 CAMERA CALIBRATION
% Calibration plate
squareSize = 5; % [mm]

disp('Started camera calibration.');

% Reading images from the specified path
disp('Reading images from path...');
distortedCheckerboardImages = imageDatastore(pathDistortedCheckerboard);
distortedCheckerboardImageFileNames = distortedCheckerboardImages.Files;

distortedLaserImages = imageDatastore(pathDistortedLaser);
distortedLaserImageFileNames = distortedLaserImages.Files;

nPoses = length(distortedCheckerboardImages.Files); % Number of poses/images

% Calibrate camera with distorted images
[distortedCameraParams, imagesUsed, estimationErrors] = calibrate_camera(distortedCheckerboardImageFileNames, squareSize);
disp([num2str(sum(imagesUsed)), '/', num2str(nPoses), ' patterns successfully detected.']);
save(strcat(path,"distortedCameraParams.mat"), "distortedCameraParams"); % for undistorting scan images later

% Undistort images
disp('Undistort checkerboard images...')
undistort_images(distortedCheckerboardImages, distortedCameraParams, pathUndistortedCheckerboard);

disp('Undistort laser images...')
undistort_images(distortedLaserImages, distortedCameraParams, pathUndistortedLaser);

% Load recorded angle data for each pose
disp('Reading recorded angles from path...');
load(strcat(path,"angles.mat"))

% Create poses from undistorted images by recalculating extrinsics
disp('Reading undistorted images from path...');
undistortedCheckerboardImages = imageDatastore(pathUndistortedCheckerboard);
undistortedCheckerboardImageFileNames = undistortedCheckerboardImages.Files;

% Calibrate camera with undistorted images
[undistortedCameraParams, imagesUsed, estimationErrors] = calibrate_camera(undistortedCheckerboardImageFileNames, squareSize);
disp([num2str(sum(imagesUsed)), '/', num2str(nPoses), ' patterns successfully detected.']);

% Detect checkerboard points in undistorted images for new extrinsics
[imagePoints,boardSize] = detectCheckerboardPoints(undistortedCheckerboardImageFileNames);

% Create calibration poses incorporating recorded angles
for i = 1:nPoses
    calibrationPoses(i) = Pose(undistortedCameraParams.WorldPoints, imagePoints(:,:,i), ...
                               angles(i,1), angles(i,2), undistortedCameraParams.Intrinsics, ... 
                               undistortedCameraParams.PatternExtrinsics(i), ...
                               undistortedCheckerboardImageFileNames(i));
end

% Plot calibration config
h1=figure; showExtrinsics(undistortedCameraParams, 'PatternCentric');

% Save the calculated poses for future use
save(strcat(path, "calibrationPoses.mat"), "calibrationPoses");
disp('Finished camera calibration.');

%% 2 TURNTABLE CALIBRATION
disp('Started turntable calibration.');

% Define initial
w1 = [1 0 0]';
w2 = [0 0 1]';
q = [5 5 0]';
s0 = [w1' w2' q']';

% Reference pose is calibrationPose(1) (by definition)
T_CW_ref = calibrationPoses(1).extrinsics.A;

% Run optimization
[s, error] = run_extrinsics_optimization(s0, calibrationPoses);

% Extract results
w1 = s(1:3);
w2 = s(4:6);
q = s(7:9);

% Save optimized extrinsics
save(strcat(path,"optimizedExtrinsics.mat"), "w1", "w2", "q", "T_CW_ref");
disp('Finished turntable calibration.');

%% 3 LASER PLANE CALIBRATION
disp('Started laser plane calibration.');

% Filter/mask laser images
disp('Masking laser images...')
undistortedLaserImages = imageDatastore(pathUndistortedLaser);
mask_images(undistortedLaserImages, pathMaskedLaser);

% Find laser line
maskedLaserImages = imageDatastore(pathMaskedLaser);
maskedLaserImageFileNames = maskedLaserImages.Files;

% Settings for line detection
I = imread(maskedLaserImageFileNames{1}); % Read the first image to get its size
resolution = size(I, 1); % [height = width]
max_line_width = 40 * resolution / 2592;
contrast_high = 60; % 10 orig
contrast_low = 0.3 * contrast_high;
roi = [0, 0, resolution, resolution];

calibrationPoints = [];
textprogressbar('Finding laser lines: ');
for i = 1:nPoses
    currentPose = calibrationPoses(i);
    
    % Define region of interest based on calibration pattern
    imagePoints = currentPose.imagePoints;
    nonNaNRows = all(~isnan(imagePoints), 2); % For rows
    imagePointsNoNaNRows = imagePoints(nonNaNRows, :);

    k = convhull(imagePointsNoNaNRows);
    hullPoints = imagePointsNoNaNRows(k, :);

    % Find points in image
    points = extract_line_points(maskedLaserImageFileNames(i), roi, max_line_width, contrast_low, contrast_high);

    % Only consider points within convex hull
    in = inpolygon(points(:,1), points(:,2), hullPoints(:,1), hullPoints(:,2));
    pointsInside = points(in,:);
    pointsOutside = points(~in,:);

    % Save image with marked points (just for debug reasons)
    fig = figure;
    currentImage = imread(maskedLaserImageFileNames{i});
    imshow(currentImage);
    hold on;
    plot(pointsOutside(:,1), pointsOutside(:,2), 'r.', 'MarkerSize', 4);  
    plot(pointsInside(:,1), pointsInside(:,2), 'g.', 'MarkerSize', 4); 
    plot(currentPose.imagePoints(k,1), currentPose.imagePoints(k,2), 'g-', 'MarkerSize', 4);
    hold off;

    % Calculate 3D world points with the help of extrinsics and intrinsics
    % of that pose and knowledge of calibration plane (z = 0)
    world2d = img2world2d(pointsInside, currentPose.extrinsics, currentPose.intrinsics);
    world3d = [world2d, zeros(length(world2d),1)];

    % Calculate 3D points in camera coordinate frame
    camera3d = (currentPose.extrinsics.R * world3d' + currentPose.extrinsics.Translation')';

    % Append values to point matrix
    calibrationPoints = [calibrationPoints; camera3d];
    
    % Show progress
    textprogressbar(100 * i / nPoses);
end

% Fit plane to point cloud
planeParams = fit_plane(calibrationPoints);
textprogressbar('done');

% Save results
save(strcat(path,"planeParams.mat"), "planeParams");
disp('Finished laser plane calibration.');