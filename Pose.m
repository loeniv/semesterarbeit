classdef Pose
    %POSE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        worldPoints
        imagePoints
        nPoints
        intrinsics
        extrinsics
        theta1
        theta2
        fileName
    end
    
    methods
        function obj = Pose(worldPoints, imagePoints, theta1, theta2, intrinsics, extrinsics, fileName)
            %POSE Construct an instance of this class
            %   Detailed explanation goes here
            obj.worldPoints = worldPoints;
            obj.imagePoints = imagePoints;
            obj.nPoints = length(imagePoints);
            obj.theta1 = theta1;
            obj.theta2 = theta2;
            obj.intrinsics = intrinsics;
            obj.extrinsics = extrinsics;
            obj.fileName = fileName;
        end
        
        function cameraPoints = world2camera(obj)
            homogenousWorldPoints = [obj.worldPoints, zeros(obj.nPoints,1), ones(obj.nPoints,1)];
            T = [obj.extrinsics.R, obj.extrinsics.Translation'];
            cameraPoints = (T * homogenousWorldPoints')';
        end

        function worldPoints = camera2world(obj, cameraPoints)
            homogenousCameraPoints = [cameraPoints, ones(length(cameraPoints),1)];
            Tinv = [obj.extrinsics.R', -obj.extrinsics.R' * obj.extrinsics.Translation'];
            worldPoints = Tinv * homogenousCameraPoints';
            worldPoints = worldPoints(1:2,:)';
        end
    end
end

