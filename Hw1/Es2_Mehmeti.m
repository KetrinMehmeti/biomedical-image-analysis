%%  Exercise 2
%   The image contained in the file "disk1.jpg" needs to be improved in terms of contrast
%   sensitivity.
%   Provide the code that:
%   1) Allows the user to select a proper ROI in correspondence of EACH internal square
%   2) Performs image enhancement in the ROI
%   3) Visualize the final image with ALL internal squares enhanced.
%   Return the code and a short report, explaining your main methodological choices.

clc, clear all, close all

%% 1) Read the input image and ROI selection
img = imread('disco1.jpg');
img = im2gray(img); % Ensure it is grayscale for simplicity

% Get image size
[imgH, imgW] = size(img);

% Ensure double precision [0,1] once at the start
img = im2double(im2gray(imread('disco1.jpg')));

figure; imshow(img, []);
title('Select 12 polygonal ROIs (double-click to confirm each)');
num_ROIs = 12; 
% The number of ROIs has been selected in advance to make sure the user
% selects ALL squares

masks = cell(num_ROIs,1);
for k = 1:num_ROIs
    roi = drawpolygon('Color','y');     % interactive polygon ROI
    wait(roi);                          % user double-click to confirm
    masks{k} = createMask(roi);         % logical mask of ROI pixels
end

%% 2) Image enhancement in the ROI
method_st = @(x) imadjust(x, stretchlim(x,[0.01 0.99]), []);

img_out_st = img;
for k = 1:num_ROIs
    BW = masks{k};
    v  = img_out_st(BW);              % pixels inside ROI as a vector
    vE = method_st(v);                % enhance only those pixels
    img_out_st(BW) = vE;              % write back inside ROI
end

%% 3) Visualization of the results

figure;

subplot(1, 2, 1)
imshow(img, [])
title('Original Image')

subplot(1, 2, 2)
imshow(img_out_st, []);
title('Enhanced Image with ROIs');
