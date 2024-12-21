function tMask = mask_images(images, path)
%MASK_IMAGES Applies a basic color filtering mask to a set of images.
%   This function reads each image from the input `images` collection, 
%   applies a color filtering mask that highlights the blue channel over the average 
%   of red and green channels, and then saves the result to a specified path.
%
%   Inputs:
%       images - A collection of images, typically an imageDatastore object.
%       path - A string specifying the directory where the masked images will be saved.
%
%   Outputs:
%       tMask - An array containing masking times for each image
%
%   The function does not return any values. Masked images are saved with the suffix "_masked.png"
%   in the directory specified by the `path` argument.

    nPoses = length(images.Files); % Number of poses/images
    tMask = zeros(nPoses, 1);

    textprogressbar('Masking images: ');

    for i = 1:nPoses 
        tic;
        % Read image
        image = readimage(images, i); % Read image

        % Define thresholds for channel 1 based on histogram settings
        channel1Min = 0.000;
        channel1Max = 255.000;
        
        % Define thresholds for channel 2 based on histogram settings
        channel2Min = 0.000;
        channel2Max = 255.000;
        
        % Define thresholds for channel 3 based on histogram settings
        channel3Min = 112.000;
        channel3Max = 255.000;
        
        % Create mask based on chosen histogram thresholds
        sliderBW = (image(:,:,1) >= channel1Min ) & (image(:,:,1) <= channel1Max) & ...
            (image(:,:,2) >= channel2Min ) & (image(:,:,2) <= channel2Max) & ...
            (image(:,:,3) >= channel3Min ) & (image(:,:,3) <= channel3Max);
        BW = sliderBW;
        
        % Initialize output masked image based on input image.
        maskedImage = image;
        
        % Set background pixels where BW is false to zero.
        maskedImage(repmat(~BW,[1 1 3])) = 0;    
        
        % Change to greyscale
        grayImage = rgb2gray(maskedImage);
        
        % Formatting file name
        num = i - 1;
        numStr = get_number_string(nPoses, num);
        
        % Save to file
        imwrite(grayImage, strcat(path, numStr, "_masked.png")); % Save masked image

        % Show progress
        textprogressbar(100 * i / nPoses);

        % Save time
        tMask(i) = toc;
    end

    textprogressbar('done');
end
