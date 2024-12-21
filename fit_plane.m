function params = fit_plane(points)
%FITPLANE Fits a plane to a set of points in 3D space using least squares.
%
%   params = FITPLANE(points) computes the parameters of a plane (ax + by + c = z)
%   that best fits a set of 3D points in the least squares sense. This function assumes
%   that the input points are in a Nx3 matrix where each row represents a point in 
%   3D space as (x, y, z).
%
%   Input:
%       points - A Nx3 matrix where N is the number of 3D points. Each row of the
%                matrix represents a single point in 3D space with coordinates (x, y, z).
%
%   Output:
%       params - A 3x1 vector [a; b; c] which are the parameters of the fitted plane
%                in the form ax + by + c = z.
%
%   Example:
%       points = [1 2 3; 4 5 6; 7 8 9; 2 3 4];
%       params = fitPlane(points);
%       % This will return the parameters of the plane fitting the points.
%
%   Note:
%       This implementation uses the pseudo-inverse to compute the plane parameters,
%       which is more numerically stable than using the inverse directly. However,
%       for a large number of points, or points that are nearly collinear, the
%       computation may still be susceptible to numerical inaccuracies.
%       An alternative calculation method is also provided. Users may consider
%       allowing selection between methods based on their specific needs or the
%       nature of their data.
%
%   See also: pinv

    % Pseudo-inverse method
    A = [points(:,1:2), ones(length(points),1)];
    b = points(:,3);
    paramsPseudoInverse = pinv(A) * b; % Recommended for general use

    % Direct method (alternative)
    x = points(:,1);
    y = points(:,2);
    z = points(:,3);

    a11 = sum(x.^2);
    a12 = sum(x.*y);
    a13 = sum(x);
    a22 = sum(y.^2);
    a23 = sum(y);
    a33 = length(x);

    A_direct = [a11 a12 a13; 
                a12 a22 a23;
                a13 a23 a33];

    b_direct = [sum(x.*z); sum(y.*z); sum(z)];

    paramsDirect = A_direct \ b_direct; % Use if the data is expected to be well-conditioned

    % Choose the method based on your preference or conditions
    params = paramsPseudoInverse; % Default to pseudo-inverse method for stability
    % params = paramsDirect; % Uncomment if preferring the direct method

end