%% Exercize 2

% Given the file h3_loopMRI.mat, containing the variable slice6, representing the series of 25
% images (uint16) acquired during a cardiac beat for a short-axis section in a patient, write the
% code (and a brief report to explain and justify the choices made) that, in the most automated
% way (i.e., minimizing the user interaction), attempts to perform the segmentation of the
% endocardium of the left ventricle (LV) for each frame (please consider that the papillary
% muscles that you see inside the cavity should be considered as part of the cavity).

% The coordinates of the LV contour for each frame have to be extracted in clockwise direction
% and saved.
% At the end of the segmentation, the code should visualize the plot of the LV volume over
% time for the analyzed slice, computed in ml (use variables xres, yres e zres containing
% resolution in ml), and visualize for each frame the endocardial contours overlapped in green
% on the original image.

clear all, close all, clc

%% Data loading

load('h3_loopMRI.mat', 'slice6');

% Removes dimensions equal to one
slice6 = squeeze(slice6);

% Number of Frames
numFrames = size(slice6, 3);

%% Normalization
slice6Norm = [];

% Conversion in double and normalization between 0 and 1
for i = 1:numFrames
    slice6Norm(:, :, i) = im2double(slice6(:, :, i));
end

%% Visualization

figure
sliceViewer(slice6Norm);
title('Original Slices')

%% Contrast enhancement
slice6Enh = [];

for i = 1:numFrames

    % Apply adaptive histogram equalization for contrast enhancement
    slice6Enh(:, :, i) = adapthisteq(slice6Norm(:, :, i));
end

%% Visualization Contrast enhancement with adaptive histogram equalization

figure
sliceViewer(slice6Enh);
title('Contrast enhancement with adapthisteq')

%% Canny edge detection

% Preallocate for edge images
edges_canny = false(size(slice6Norm)); 
edges_closed = false(size(slice6Norm)); 

% Small disk to close gaps
se = strel('square', 3);

for i = 1:numFrames
    edges_canny(:, :, i) = edge(slice6Enh(:, :, i), 'Canny', [0 0.15]); % Apply Canny edge detection

    % Morphological closing to fill gaps in edges
    edges_closed(:, :, i) = imclose(edges_canny(:, :, i), se);
end

%% Visualize edges

figure
sliceViewer(edges_closed);
title('Edge detection with Canny')

%% Edge filling

% Initialize mask
edges_filled = false(size(slice6Norm)); 

for i = 1:numFrames
    % Morphological closing to fill gaps in edges
    edges_filled(:, :, i) = imfill(edges_closed(:, :, i), 'holes');
end

%% Visualization 

figure
sliceViewer(edges_filled);
title('Filled regions - Canny')

%% Left ventricle selection

% Coordinates of a point inside the LV in the first slice
% These two points are going to be used in the bwselect function so that
% only the component connected to this point is selected (the left ventricle)
x = 114;
y = 111;
LVregion = false(size(slice6Norm));

for i = 1:numFrames
    % Extract contours of the left ventricle from the filled edges
    LVregion(:, :, i) = bwselect(edges_filled(:, :, i), x, y, 4);
end

%% Visualize contours

[H, W, S] = size(slice6);

% Preallocate RGB volume for sliceViewer (H x W x S x 3)
slice6Final = zeros(H, W, S, 3);

for i = 1:numFrames

    % Gray Scale conversion
    % mat2gray is performed in order to allow visualization of the original
    % image overlayed with contours of the left ventricle.
    % This step rescales the image so that it is visible (without it the 
    % green of the contours dominate the image)
    base = mat2gray(slice6Norm(:, :, i));

    slice6Final(:,:,i,1) = base;
    slice6Final(:,:,i,2) = base;
    slice6Final(:,:,i,3) = base;

    % Select Contours
    LVcontours = bwperim(LVregion(:, :, i));

    % Create an RGB image by overlaying the contours on the original image
    slice6Final(:, :, i, 2) = slice6Final(:, :, i, 2) + LVcontours; % Green channel
end

figure
sliceViewer(slice6Final);
title('Original Slices with LV contours (green)')

%% LV coordinates clockwise

for i = 1: numFrames
    
    % Store the coordinates of the LV (extracted in clockwise direction)
    LVcoordinates(i, 1) = bwboundaries(LVregion(:, :, i));
end


%% LV Volume computation

% Load xres, yres and zres
xres = load('h3_loopMRI.mat', 'xres');
yres = load('h3_loopMRI.mat', 'yres');
zres = load('h3_loopMRI.mat', 'zres');

for i = 1:numFrames
    % Calculate the volume of the left ventricle for each frame
    % Expressed in mm^3
    LVvolume(i, 1) = nnz(LVregion(:, :, i)) .* xres.xres .* yres.yres .* zres.zres;

    % Conversion in ml
    LVvolume(i, 1) = LVvolume(i, 1) / 1000; 
end

%% Visualize LV volume over time

figure;
plot(1:numFrames, LVvolume, '-o', 'LineWidth', 2);
xlabel('Frame Number');
ylabel('LV Volume (ml)');
title('Left Ventricle Volume Over Time');
grid on;
