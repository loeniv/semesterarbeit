function tform = var2tform(w1, theta1, w2, theta2, q)
%VAR2TFORM Combines two axis-angle rotations and a translation into a single transformation matrix.
%
% Syntax:
%   tform = var2tform(w1, theta1, w2, theta2, q)
%
% Description:
%   This function takes two sets of axis-angle representations for rotations
%   and a translation vector, converts the rotations into rotation matrices,
%   and then combines these rotations and the translation into a single
%   transformation matrix. This matrix represents the sequential application
%   of these rotations followed by the translation.
%
% Inputs:
%   w1 - 3x1 vector representing the axis of rotation for the first rotation.
%   theta1 - Scalar value representing the angle of rotation in radians for the first rotation.
%   w2 - 3x1 vector representing the axis of rotation for the second rotation.
%   theta2 - Scalar value representing the angle of rotation in radians for the second rotation.
%   q - 3x1 vector representing the translation.
%
% Outputs:
%   tform - 4x4 transformation matrix representing the combined rotation and translation.
%
% Examples:
%   % Combining rotations around the x-axis and y-axis with a translation
%   w1 = [1; 0; 0];
%   theta1 = pi/4; % 45 degrees in radians
%   w2 = [0; 1; 0];
%   theta2 = pi/6; % 30 degrees in radians
%   q = [1; 2; 3]; % Translation vector
%   tform = var2tform(w1, theta1, w2, theta2, q);
%
% Note:
%   The rotations are applied sequentially: first the rotation defined by (w1, theta1),
%   followed by the rotation defined by (w2, theta2). The translation is then applied
%   after these rotations. The function constructs a homogeneous transformation matrix
%   that includes both rotation and translation.
%
% See also: axang2rotm

    % Convert the first axis-angle representation to a rotation matrix
    axang1 = [w1; theta1]';
    R_w1 = axang2rotm(axang1);
    
    % Convert the second axis-angle representation to a rotation matrix
    axang2 = [w2; theta2]';
    R_w2 = axang2rotm(axang2);
    
    % Construct transformation matrix
    tform = [R_w1 * R_w2, (eye(3) - R_w1 * R_w2) * q; 0, 0, 0, 1];
end

