function f = cost_function(s, calibrationPoses)
%COST_FUNCTION Calculates the cost for camera calibration optimization.
%
% Syntax:  f = cost_function(s, calibrationPoses)
%
% Inputs:
%   s              - A 9-element vector representing the parameters to be optimized.
%                    These include three elements for each of two rotation vectors
%                    (w1 and w2) and three elements for the translation vector (q).
%   calibrationPoses - An array of calibration pose objects, each containing
%                    information about the world points and angles for a specific
%                    camera pose used in the calibration process.
%
% Outputs:
%   f              - The cost value, representing the sum of squared differences
%                    between measured points and their expected positions after
%                    applying the transformations defined by the parameters in s.
%
% Description:
%   This function computes the cost value used in the optimization process of
%   camera calibration. It utilizes the input parameters (s) to define rotation
%   and translation transformations. These transformations are applied to the
%   reference points within the calibrationPoses objects to align them with their
%   measured counterparts. The function calculates the cost as the sum of squared
%   distances between these aligned points and the actual measured points across
%   all poses. The goal of the optimization process is to minimize this cost,
%   thereby refining the camera's calibration parameters for improved accuracy in
%   pose estimation.

    % Extract rotation and translation parameters from the input vector s
    w1x = s(1); w1y = s(2); w1z = s(3);
    w1 = [w1x, w1y, w1z]';  % Rotation vector 1

    w2x = s(4); w2y = s(5); w2z = s(6);
    w2 = [w2x, w2y, w2z]';  % Rotation vector 2

    qx = s(7); qy = s(8); qz = s(9);
    q = [qx, qy, qz]';  % Translation vector

    % Define homogenouse reference pose
    XR = calibrationPoses(1).world2camera();
    XRhomo = [XR, ones(size(XR,1),1)];

    f = 0;  % Initialize the objective function value

    % Iterate over each pose/image
    nPoses = length(calibrationPoses);  % Total number of poses/images
    for i = 1 : nPoses
        XMi = calibrationPoses(i).world2camera();  % Extract measured points for the current pose/image

        % Calculate the transformed reference pose using the given rotations and translation
        theta1i = calibrationPoses(i).theta1;
        theta2i = calibrationPoses(i).theta2;

        T = var2tform(w1, theta1i, w2, theta2i, q); % 4x4
        XC = (T * XRhomo')'; % Nx4
        XC = XC(:,1:3); % Nx3
        
        % Accumulate the sum of squared differences
        f = f + (1/2)*norm(XMi - XC,'fro')^2;
    end      

    
end