%% Exercise 2

%       Dr. Wise wants you to automatically analyze pictures from pill blisters to understand how
%       many have been used. One pic ('blister25.mat') is given to you as a sample to be
%       analyzed, with the following incrementally difficult aims:

%       1) design and apply the filter in order to remove the additive sinusoidal noise
%       2) detect the external contours of the blister and compute its aspect ratio
%       3) remove the different illumination effect
%       4) detect the pills still in the blister and the missing ones

clear all, close all, clc

%% Image loading 

% Load the sample image data
img = load('blister25.mat');              
img = img.C; 

figure;
% Display the original image
imshow(img);
title('Original Blister Image');

%% 1) Removal of sinusoidal noise withy ideal mask

% Conversion to double
img_double = im2double(img);

% Conversion to Gray scale
img_double = rgb2gray(img_double);

% Compute the 2D Fourier Transform of the image
img_spectrum = fft2(img_double);
img_spectrum_shifted = fftshift(img_spectrum);

% Display of image Spectrum
figure;
imshow(log(1+img_spectrum_shifted), []);
colormap('jet');
title('Image Spectrum in logarithmic scale');

% Besides the central peak, the spectrum shows 16 additional peaks along 
% the horizontal frequency axis (8 on each side), all equally spaced by 
% 186 pixels. Based on this observation, an ideal notch mask was designed 
% by placing circular notches of fixed radius at those symmetric frequency 
% locations, in order to selectively attenuate the sinusoidal components 
% while preserving the rest of the image content.

% Number of rows and columns saved in advance for simplicity
[R, C] = size(img_double);

% Frequency resolution computation
freq_resolution_y = 1 / R;              % R -> rows
freq_resolution_x = 1 / C;              % C -> columns

% Position of the central peak of the image (DC component)
center_x = 1489;
center_y = 1985;

% First left peak position (found by visual inspection)
first_peak_x   = 1303;
peak_spacing   = 186;    % pixel spacing between adjacent peaks
num_peaks_side = 8;      % number of peaks per side

% For symmetry, the sinusoidal noise frequencies are computed
% only for the 8 peaks on one side (left); the right-side
% peaks correspond to the same |fx| values.
peak_positions_x = zeros(1, num_peaks_side);
freq_noise_x     = zeros(1, num_peaks_side);   % |fx| in cycles/pixel

for k = 1:num_peaks_side
    % x–position of the k‑th peak on the left of the spectrum
    peak_positions_x(k) = first_peak_x - (k-1) * peak_spacing;

    % corresponding spatial frequency magnitude (cycles/pixel)
    freq_noise_x(k) = abs(center_x - peak_positions_x(k)) * freq_resolution_x;
end


% Generate 2-D coordinate grids (u for columns, v for rows) so that we can
% compute, for every frequency location (v,u), its distance from the chosen
% peak/center when building the notch mask.
[u, v] = meshgrid(1:C, 1:R);  

% Preparation of the mask
mask = ones(R, C);

% The radius value was selected empirically by testing several alternatives 
% and choosing the one that provided the best trade‑off between effective 
% attenuation of the sinusoidal peaks and preservation of the useful image content.
radius = 60; 
D = ones(R, C);

for i=1:8
    % Create a notch filter for each sinusoidal noise
    D1 = sqrt((u - center_x+(186*i)).^2 + (v - center_y).^2);
    D2 = sqrt((u - center_x-(186*i)).^2 + (v - center_y).^2);
    % Set the mask to zero for frequencies within the notch radius
    mask(D1 < radius) = 0;  
    mask(D2 < radius) = 0; 
end 

% Display the mask
figure;
imshow(mask);
title('Ideal mask applied to remove sinusoidal noise')

% Multiplication of the mask with the spectrum of the image
F_filtered = img_spectrum_shifted .* mask;

% Inverse fourier transform of the image
img_filtered_line = real(ifft2(ifftshift(F_filtered)));

% Display the filtered image
figure;
imshow(img_filtered_line, []);
title('Filtered image with ideal notch filter')

%%  Smoothing of filtered image with average filter

% Averaging filter
kernel19 = ones(19,19) * 1/361;
img_filtered_avg = imfilter(img_filtered_line, kernel19, "same", "conv");

% Display of the smoothed image
figure
imshow(img_filtered_avg, []);
title('Filtered and smoothed image');

% An averaging filter was applied to the filtered image because, after 
% removing the sinusoidal noise with an ideal notch filter, some residual 
% noise was still present. This remaining noise interfered with edge 
% detection, which was necessary to complete the following steps of the 
% exercise.

%% 2) Detect the external contours of the blister 

% Compass Masks definition
sobel_mask = fspecial("sobel");
sobel_mask45 = [2, 1, 0; 1, 0, -1; 0, -1, -2];
sobel_mask90 = rot90(sobel_mask);
sobel_mask135 = rot90(sobel_mask45);
sobel_mask180 = rot90(sobel_mask90);
sobel_mask225 = rot90(sobel_mask135);
sobel_mask270 = rot90(sobel_mask180);
sobel_mask315 = rot90(sobel_mask225);

edges_sobel = imfilter(img_filtered_avg, sobel_mask, 'conv', 'replicate');
edges_sobel45 = imfilter(img_filtered_avg, sobel_mask45, 'conv', 'replicate');
edges_sobel90 = imfilter(img_filtered_avg, sobel_mask90, 'conv', 'replicate');
edges_sobel135 = imfilter(img_filtered_avg, sobel_mask135, 'conv', 'replicate');
edges_sobel180 = imfilter(img_filtered_avg, sobel_mask180, 'conv', 'replicate');
edges_sobel225 = imfilter(img_filtered_avg, sobel_mask225, 'conv', 'replicate');
edges_sobel270 = imfilter(img_filtered_avg, sobel_mask270, 'conv', 'replicate');
edges_sobel315 = imfilter(img_filtered_avg, sobel_mask315, 'conv', 'replicate');

edges_stack = cat(3, ...
    edges_sobel, ...
    edges_sobel45, ...
    edges_sobel90, ...
    edges_sobel135, ...
    edges_sobel180, ...
    edges_sobel225, ...
    edges_sobel270, ...
    edges_sobel315);

[edges_max, dir_idx] = max(edges_stack, [], 3);

%% Display of the binary image containing the filled blister 

threshold = 0.15 * max(edges_max(:));      % Set a threshold as 15% of the maximum edge magnitude (thus choice was made after several trials)
edges_binary = edges_max > threshold;      % Convert edge magnitude image to a binary edge image

figure;
imshow(edges_max, []);
title('Edge Detection with Compass masks');

figure;
imshow(edges_binary, []);                  % Display the binary edge image
title('Binary Edge Detected Image');
 
edges_binary_cropped_avg = edges_binary(12:end-10, 12:end-10);  % Crop 12 pixels from each border to remove the white contour
edges_filled = imfill(edges_binary_cropped_avg, "holes");       % Fill holes inside connected edge regions
figure;
imshow(edges_filled, []);                  % Display the filled binary edge image
title('Binary Edge Detected Image Filled');


%% 2) Aspect ratio computation

rows_with_one = sum(any(edges_filled, 2));      % Counts rows with at least one 1
cols_with_one = sum(any(edges_filled, 1)) - 2;      % Counts columns with at least one 1

% 2 columns were subtracted because after showing edges_filled I noticed a
% small noise outside the blister consisting in 3 white pixels distributed
% in 2 columns.
% The number of rows wasn't changed since those specific rows were already 
% counted as a part of the blister

aspect_ratio = cols_with_one / rows_with_one;   % Calculates the aspect ratio (width / height)

fprintf('Aspect ratio: %.4f\n', aspect_ratio);  % Prints the aspect ratio to the command window

%% 3) Remove the different illumination effect

% Adaptive Histogram
img_adapthist = adapthisteq(img_filtered_avg, 'ClipLimit', 0.01, 'NumTiles',[16 16]);

figure;
imshow(img_adapthist,[]);
title('Image Normalized with adaptive histogram equalization');

% Histogram equalization

% Image saturation
img_saturation = img_adapthist;
img_saturation(img_adapthist > 0.55) = 0.55;

lowHigh = stretchlim(img_saturation, [0.01 0.99]);    % exclude 1% at each extremity 
img_histeq = imadjust(img_saturation, lowHigh, [0 0.55]);

figure;
imshow(img_histeq, [])
title('Histogram Equalization with asymmetric boundaries')

%%  4) Detect the pills still in the blister and the missing ones

% Edge detection with Compass masks 

% Detect contours using Compass masks defined previously

edges_sobel = imfilter(img_histeq, sobel_mask, 'conv', 'replicate');
edges_sobel45 = imfilter(img_histeq, sobel_mask45, 'conv', 'replicate');
edges_sobel90 = imfilter(img_histeq, sobel_mask90, 'conv', 'replicate');
edges_sobel135 = imfilter(img_histeq, sobel_mask135, 'conv', 'replicate');
edges_sobel180 = imfilter(img_histeq, sobel_mask180, 'conv', 'replicate');
edges_sobel225 = imfilter(img_histeq, sobel_mask225, 'conv', 'replicate');
edges_sobel270 = imfilter(img_histeq, sobel_mask270, 'conv', 'replicate');
edges_sobel315 = imfilter(img_histeq, sobel_mask315, 'conv', 'replicate');

edges_stack = cat(3, ...
    edges_sobel, ...
    edges_sobel45, ...
    edges_sobel90, ...
    edges_sobel135, ...
    edges_sobel180, ...
    edges_sobel225, ...
    edges_sobel270, ...
    edges_sobel315);

[edges_max, dir_idx] = max(edges_stack, [], 3);

figure;
imshow(edges_max, []);
title('Edge Detection with Compass masks');

threshold1 = 0.10 * max(edges_max(:)); 
edges_binary_adapt1 = edges_max > threshold1; % Binary image 

% This edge detection is going to be used later to detect only the non-used
% pills
threshold2 = 0.15 * max(edges_max(:)); 
edges_binary_adapt2 = edges_max > threshold2; % Binary image 

figure; 
imshow(edges_binary_adapt1, []);
title('Edge Detection with Compass masks');

%% Morphological cleaning to obtain the mask containing ALL the pills

minArea = 400;
edges_binary_compass = bwareaopen(edges_binary_adapt1, minArea, 8); 

se = strel('disk', 5);
edges_binary_compass = imclose(edges_binary_compass, se);

% Find blister bounding box from edges_filled (filled blister contour)
[i_blister, j_blister] = find(edges_filled == 1);
min_row = min(i_blister);
max_row = max(i_blister);
min_col = min(j_blister);
max_col = max(j_blister);

edges_cleaned_cropped = edges_binary_compass; 

% Crop with 10-pixel margin INSIDE the blister contour
margin = 15;
edges_cleaned_cropped(1:min_row+margin-1, :) = 0;           % Top margin
edges_cleaned_cropped(max_row-margin+1:end, :) = 0;         % Bottom margin  
edges_cleaned_cropped(:, 1:min_col+margin-1) = 0;           % Left margin
edges_cleaned_cropped(:, max_col-margin+1:end) = 0;         % Right margin

edges_filled_pills = imfill(edges_cleaned_cropped, 'holes');

se = strel('disk', 100);
edges_filled_pills = imopen(edges_filled_pills, se);

figure;
imshow(edges_filled_pills, [])
title('Pills detected')

% Count the number of detected pills in total
[K, numTOT] = bwlabel(edges_filled_pills, 8); 
% Display the number of detected pills
fprintf('Number of detected pills in total: %d\n', numTOT);

%% Morphological cleaning to obtain the mask containing the UNUSED pills

edges_thin = bwmorph(edges_binary_adapt2, 'thin');

% Perform morphological operations to clean up the binary image
se = strel('disk', 5);  % Create a structural element

edges_cleaned = imclose(edges_thin, se);  % Close gaps in the edges

% Instead of cropping, set border pixels to zero to remove edge artifacts
edges_cleaned_cropped = edges_cleaned;
edges_cleaned_cropped(1:11, :) = 0;           % Set top 11 rows to zero
edges_cleaned_cropped(end-10:end, :) = 0;     % Set bottom 11 rows to zero
edges_cleaned_cropped(:, 1:11) = 0;           % Set left 11 columns to zero
edges_cleaned_cropped(:, end-10:end) = 0;     % Set right 11 columns to zero

figure;
imshow(edges_cleaned_cropped, [])
title('Cropped image after closure of boundaries')

%% Filling the unused pills
edges_cleaned_crop = edges_cleaned_cropped;
edges_filled_pills_unused = imfill(edges_cleaned_crop, 'holes');

figure;
imshow(edges_filled_pills_unused, []);
title('Filled unused Pills in Blister');

%% Unused Pills detection

se = strel('disk', 80);
edges_filled_pills_unused = imopen(edges_filled_pills_unused, se);

% Finalize the processing by displaying the cleaned and filled pills image
figure;
imshow(edges_filled_pills_unused, []);
title('Final Image of Pills in Blister');

% Count the number of unused pills
[L, numUNUSED] = bwlabel(edges_filled_pills_unused, 8); 
fprintf('Number of unused pills: %d\n', numUNUSED);
fprintf('Number of used pills: %d\n', numTOT-numUNUSED);


%% Used pills detection
edges_pills_used = edges_filled_pills - edges_filled_pills_unused;

% Set all -1 values to 0
edges_pills_used(edges_pills_used == -1) = 0;

% Morphological processing of the mask
% Perform morphological operations to further clean the edges 

% This step has been performed in order to eliminate the small borders of
% the unused pills caused by the different morphological processes applied
% to obtain 'edges_filled_pills' and 'edges_filled_pills_unused'
se = strel('disk', 9);  
edges_pills_used_cleaned = imopen(edges_pills_used, se);  % Open to remove small objects

figure;
imshow(edges_pills_used_cleaned, []);
title('Filled used Pills in Blister');

%% Final display of the blister

[i_unused, j_unused] = find(edges_filled_pills_unused == 1);
[i_used, j_used]     = find(edges_pills_used_cleaned == 1);

figure;
imshow(img_filtered_avg, []);

hold on;

% Plot UNUSED pills in YELLOW
plot(j_unused, i_unused, '.g', 'MarkerSize', 10, 'LineWidth', 1.5);

% Plot USED pills in RED
plot(j_used, i_used, '.r', 'MarkerSize', 10, 'LineWidth', 1.5);

title('Pills: Green=Unused, Red=Used');
legend('Unused Pills', 'Used Pills', 'Location', 'best');
hold off;

