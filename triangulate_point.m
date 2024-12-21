function p = triangulate_point(imagePoint, planeParams, K)
%TRIANGULATE_POINT Triangulates the 3D position of a point from its image coordinates.
%
%   p = TRIANGULATE_POINT(imagePoint, planeParams, K) calculates the 3D coordinates
%   of a point given its image coordinates, the parameters of a plane in which the
%   point lies, and the camera's intrinsic matrix K.
%
%   Inputs:
%       imagePoint - A 2-element vector [u, v] representing the coordinates of the
%                    point in the image.
%       planeParams - A 3-element vector [a, b, c] representing the parameters of the
%                     plane equation ax + by + c = z in which the point lies.
%       K - The 3x3 camera intrinsic matrix.
%
%   Output:
%       p - A 3-element vector [x, y, z] representing the 3D coordinates of the point.
%
%   Note:
%       This function assumes a pinhole camera model and a plane equation of the form
%       ax + by + c = z. It uses the geometric properties of perspective projection and
%       plane geometry to calculate the 3D position.

    % Extend imagePoint to homogeneous coordinates
    u = [imagePoint; 1]; % [u, v, 1]'

    % Extract plane parameters
    a = planeParams(1);
    b = planeParams(2);
    c = planeParams(3);

    % Plane normal vector and a point on the plane
    n = [a, b, -1]'; % Normal vector of the plane
    q = [0, 0, c]'; % A point on the plane, assuming x=y=0 for simplicity

    % Calculate the intersection point's depth (z-coordinate in camera frame)
    denom = n' * (K \ u); % Equivalent to inv(K)*u but more efficient
    num = n' * q;
    zc = num / denom;

    % Calculate the 3D point coordinates in camera frame
    p = (K \ u) * zc; % Again, using K\u for efficiency
end