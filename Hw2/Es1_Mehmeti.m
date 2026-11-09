%% Exercise 1

    % The image contained in the file "hand.mat" needs to be segmented in order to obtain the
    % contours of the bones in the fingers.

    % After performing pre-processing of your choice (histogram stretching, de-noising, edge
    % enhancement, …), proceed with segmenting the structure of interest by:

    % 1) edge detection using the "compass masks" approach created from the Sobel kernel
    % 2) edge detection by another method of your choice, that you think appropriate for
    % solving the assigned task

    % For each method, in separate figures with relevant titles, plot the contours resulting from
    % the segmentation as red dots overimposed to the original image.

    clear all, close all, clc

%% Image loading

% Loading the image data from the .mat file
img = load('hand.mat'); 

% Initial visualization of the original image in order to choose what kind
% of pre-processing better fits the image
figure;
subplot (1, 2, 1)
imshow(img.J, []);           % Display the original image
title('Original Image');     % Title for the original image

subplot(1, 2, 2)
imhist(img.J)                % Display the original Histogram
title('Original Histogram')

%% Pre-processing with Averaging filter

% After looking at the image, it's possible to notice a Gaussian Noise.
% In order to remove such noise diferent averaging filters will be applied, 
% before choosing which one better fits the image.

kernel_3x3 = ones(3, 3)./9;
kernel_5x5 = ones(5, 5)./25;
kernel_7x7 = ones(7, 7)./49;
kernel_9x9 = ones(9, 9)./81;

% Apply the 3x3 averaging filter to further reduce noise
img_averaged_3x3 = imfilter(img.J, kernel_3x3, 'replicate');

% Apply the 5x5 averaging filter to further reduce noise
img_averaged_5x5 = imfilter(img.J, kernel_5x5, 'replicate');

% Apply the 7x7 averaging filter to further reduce noise
img_averaged_7x7 = imfilter(img.J, kernel_7x7, 'replicate');

% Apply the 9x9 averaging filter to further reduce noise
img_averaged_9x9 = imfilter(img.J, kernel_9x9, 'replicate');

% The 4 averaged images are not shown in a subplot all together since the
% images would have been too small to visually assess which one is the best
% choice

figure 
imshow(img_averaged_3x3, []);
title('3x3 Averaged Image');

figure
imshow(img_averaged_5x5, []);
title('5x5 Averaged Image');

figure
imshow(img_averaged_7x7, []);
title('7x7 Averaged Image');

figure
imshow(img_averaged_9x9, []);
title('9x9 Averaged Image');

% After visually inspecting the four images I believe the best choice is
% the one that uses a 5x5 kernel, because when a 3x3 averaging filter is applied
% there is still some noise present, but when using the 7x7 and 9x9 kernels
% the image appears blurred

%% Pre-processing with Gaussian filter

img_gauss1 = imgaussfilt(img.J, 1);
img_gauss1_5 = imgaussfilt(img.J, 1.5);
img_gauss2 = imgaussfilt(img.J, 2);
img_gauss3 = imgaussfilt(img.J, 3);

% Also in this section the 4 images are shown separately and not in a
% subplot to ensure the best visualization possible of the resulting images
figure;
imshow(img_gauss1, []);
title('Gaussian Filtered Image (σ=1)');

figure;
imshow(img_gauss1_5, []);
title('Gaussian Filtered Image (σ=1.5)');

figure;
imshow(img_gauss2, []);
title('Gaussian Filtered Image (σ=2)');

figure;
imshow(img_gauss3, []);
title('Gaussian Filtered Image (σ=3)');

% After visually inspecting the four images, the best choice turned out to be the one 
% pre-processed with a Gaussian filter with σ=2. With lower σ values, the images 
% retained too much noise, which negatively affected the edge detection results. 
% The image filtered with σ=2 produced cleaner and more stable edges, making it 
% the most suitable option for further processing.

%% Visualization of de-noised image and histogram

% Renaming the final selection 
img_denoised = img_gauss2;

figure;
% Display the of the de-noised image
subplot(1, 2, 1)
imshow(img_denoised, []);

subplot(1, 2, 2)
% Display the histogram of the de-noised image
imhist(img_denoised);
title('De-noised Image Histogram');

%% Image enhancement

% Histogram stretching
lowHigh = stretchlim(img_denoised, [0.01 0.99]);    % exclude 1% at each extremity
img_contrast = imadjust(img_denoised, lowHigh, []);

figure;
subplot(2,2,1); 
imshow(img_denoised, []); 
title('De-noised image');

subplot(2, 2, 2); 
imhist(img_denoised);
title('De-noised Image Histogram');

subplot(2, 2, 3); 
imshow(img_contrast, []); 
title('De-noised and enhanced image');

subplot(2, 2, 4);
% Display the histogram of the enhanced image
imhist(img_contrast);
title('De-noised and enhanced Image Histogram');

%% 1) Edge detection with compass mask

% Definition of the Sobel masks in the 8 possible directions
sobel_mask = fspecial("sobel");
sobel_mask45 = [2, 1, 0; 1, 0, -1; 0, -1, -2];
sobel_mask90 = rot90(sobel_mask);
sobel_mask135 = rot90(sobel_mask45);
sobel_mask180 = rot90(sobel_mask90);
sobel_mask225 = rot90(sobel_mask135);
sobel_mask270 = rot90(sobel_mask180);
sobel_mask315 = rot90(sobel_mask225);

% Convolution of the Sobel masks with the de-noised and enhanced image for
% edge detection in each direction defined
edges_sobel = imfilter(img_contrast, sobel_mask, 'conv', 'replicate');
edges_sobel45 = imfilter(img_contrast, sobel_mask45, 'conv', 'replicate');
edges_sobel90 = imfilter(img_contrast, sobel_mask90, 'conv', 'replicate');
edges_sobel135 = imfilter(img_contrast, sobel_mask135, 'conv', 'replicate');
edges_sobel180 = imfilter(img_contrast, sobel_mask180, 'conv', 'replicate');
edges_sobel225 = imfilter(img_contrast, sobel_mask225, 'conv', 'replicate');
edges_sobel270 = imfilter(img_contrast, sobel_mask270, 'conv', 'replicate');
edges_sobel315 = imfilter(img_contrast, sobel_mask315, 'conv', 'replicate');


% Definition of 3D stack of these 8 images
edges_stack = cat(3, ...
    edges_sobel, ...
    edges_sobel45, ...
    edges_sobel90, ...
    edges_sobel135, ...
    edges_sobel180, ...
    edges_sobel225, ...
    edges_sobel270, ...
    edges_sobel315);

% Selecting the maximum value amongst all images for each pixel
[edges_max, dir_idx] = max(edges_stack, [], 3);

% Display the edge-detected image and its direction
figure;
imshow(edges_max, []);
title('Edge Detection with Compass masks');

%% Superimpose the edges on the original image with processing on the edges detected

% Further processing involves thresholding the edge-detected image
threshold = 0.15 * max(edges_max(:)); % Define a threshold based on the maximum value ()
edges_binary = edges_max > threshold; % Create a binary image from the edge-detected image

% Note: the threshold has been decided empirically through trial and error
% by assessing visually which threshold was the best in this case

% Display the binary edge-detected image
figure;
imshow(edges_binary, []);
title('Binary Edge Detected Image');

% Display the binary edge-detected image with contours superimposed
figure;
imshow(img_contrast, []);
hold on;
contour(edges_binary, 'LineColor', 'r', 'LineWidth', 1);
title('Method: Compass Masks with thresholding');
hold off;

%% Morphological image processing
minArea = 40; 
edges_clean = bwareaopen(edges_binary, minArea, 8); 

figure;
perimeters = bwperim(edges_clean, 8);
imshow(img_contrast, []);
hold on;
[r, c] = find(perimeters);
plot(c, r, 'r.', 'MarkerSize', 2);
title('Method: Compass masks with thresholding and morphological processing')
hold off;

%% 2) Edge detection with Canny Method
% Apply Canny edge detection on the de-noised and enhanced image

% Note the image used is the on which a Gaussian Filter with sigma=3
% because when using img_denoised (which has sigma=2) the contoured image
% appears very noisy
edges_canny = edge(img_gauss3, 'Canny');

% Display the Canny edge-detected image
figure;
imshow(edges_canny, []);
title('Edges detected with Canny');

%% Display the original image with Canny edges superimposed

% Morphological Cleaning to remove small artifacts in the edge detected
% image
minArea = 50;
% This value has been decided empirically by 
% visually assessing which value was best in this case

edges_canny_clean = bwareaopen(edges_canny, minArea, 8); 

figure;
perimeters = bwperim(edges_canny_clean, 8);
imshow(img_gauss3, []);
hold on;
[r, c] = find(perimeters);
plot(c, r, 'r.', 'MarkerSize', 2);
title('Method: Canny with morphological processing')
hold off;