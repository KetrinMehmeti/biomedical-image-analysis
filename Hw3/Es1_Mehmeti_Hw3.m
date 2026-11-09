%% Exercize 1

% Given the file CMR_thorax.mat, containing the variable vol representing a series of 104
% images (uint16) of the thorax of a patient, write the code (and a brief report to explain and
% justify the choices made) that performs in the most automated way (i.e., minimizing the
% interaction with the user) the segmentation of the external contour of the thorax for each
% slice, and of the lungs in each slice in which they are visible, even partially.

% Result of lung segmentation has to be saved in a 3D binary array called IcatLUNG, of the
% same dimensions of vol, where for each slice the pixels in the segmented lung are set to 1.
% In the same way, the segmented thorax has to be saved in a 3D binary array named IcatT

% At the end of the segmentation, the code should give as a result the total volume for left
% and right lung separately, computed as number of pixel, and visualize for each slice the
% contours of the thorax in yellow, and of the lungs (when present) in magenta, both
% overlapped to the original image

clear all, close all, clc

%% Image loading

% Load the data containing the volume of images
load('CMR_thorax.mat'); 
% Note: the loading of the slices automatically generates the variable vol 

% Check basic information about the volume
volSize  = size(vol);     % [rows, columns, slices]
volClass = class(vol);    % should be 'uint16'
disp(['Volume size: ', mat2str(volSize)]);
disp(['Volume class: ', volClass]);

%% Slice visualization with sliceviewer

figure;
sliceViewer(vol);
title('Original slices');

%% Conversion to double and intensity normalization using im2double

% Preallocate a double volume with the same size as 'vol'
volNorm = zeros(volSize, 'double');

for k = 1:volSize(3)
    
    % Extract k–th slice
    Ik = vol(:,:,k);
    
    % Convert to double and normalize
    Ikd = im2double(Ik);
    
    % Store normalized slice in the output volume
    volNorm(:,:,k) = Ikd;
end

%% Contrast enhancement with imadjust

% Contrast Enhancement of each normalized slice using imadjust
for k = 1:volSize(3)
    Ik = volNorm(:,:,k);   % normalized slice in [0,1]
        
    % Apply contrast adjustment using default parameters
    MinMax = stretchlim(Ik);
    Ik_adj = imadjust(Ik, MinMax);

    % Saving the output   
    volAdj(:,:,k) = Ik_adj;
end

%% Volume visualization after contrast enhancement

figure('Name', 'Contrast ehanced volume - volshow');
volshow(volAdj);
title('Contrast enhanced slices');

%% Slice visualization after contrast enhancement

figure;
sliceViewer(volAdj);
title('Contrast enhanced slices with imadjust');

%% Thorax segmentation
% Otsu Method

% Preallocate binary arrays for thorax segmentation
IcatT = false(volSize);  % logical array

% Large disk to close thorax contour gaps
se_close_large = strel('disk', 50);    

for k = 1:volSize(3)
    
    % Extract k-th slice (contrast-enhanced, normalized [0,1])
    Ik = volAdj(:,:,k);
    
    % Global thresholding (Otsu method)
    level = graythresh(Ik);             % automatic threshold in [0,1] 
    BW    = Ik > level;                 % binarize: thorax+content = 1, air = 0
    
    % Morphological cleaning %
    % Fill holes inside the body
    BW = imfill(BW, 'holes');
    
    % Connect small gaps in thorax contour
    BW = imclose(BW, se_close_large);
    
    % Select largest connected component
    CC     = bwconncomp(BW, 8);         
    stats  = regionprops(CC, 'Area');
    
    if ~isempty(stats)
       
        % Find index of largest component
        [~, maxIdx] = max([stats.Area]);
        
        % Create mask with only the largest component (thorax)
        BW_torax = false(size(BW));
        BW_torax(CC.PixelIdxList{maxIdx}) = true;
    else
        % If no components are found all values are set to zero
        BW_torax = false(size(BW));
    end
    
    % Store result in 3D mask
    IcatT(:,:,k) = BW_torax;
end


%% Visualization of thorax mask overlay
% Otsu Method

figure('Name', 'Thorax Segmentation Results', 'NumberTitle','off');
sliceViewer(volAdj, IcatT);  
title('IcatT overlaid on volAdj (Otsu)');

%% Function for edge detection with compass masks
% This function will be later used to perform edge detection with the
% Compass Mask method

function edge_magnitude = compass_edge_detector(input_image)
% Computes edge magnitude map using 8-directional Sobel compass filters

% Get image dimensions
[img_rows, img_cols] = size(input_image);

% Standard horizontal Sobel kernel
horiz_kernel = fspecial("sobel");

% 45-degree Sobel kernel
diag45_kernel = [2, 1, 0; 1, 0, -1; 0, -1, -2];

% Generate remaining kernels by successive 90-degree rotations
kernel_90  = rot90(horiz_kernel);   % 90 degrees
kernel_135 = rot90(diag45_kernel);  % 135 degrees
kernel_180 = rot90(kernel_90);      % 180 degrees
kernel_225 = rot90(kernel_135);     % 225 degrees
kernel_270 = rot90(kernel_180);     % 270 degrees
kernel_315 = rot90(kernel_225);     % 315 degrees

% Stack all 8 kernels into a 3D tensor (rows, cols, orientation)
filter_stack = cat(3, horiz_kernel, diag45_kernel, kernel_90, kernel_135, ...
                   kernel_180, kernel_225, kernel_270, kernel_315);

% Initialize output edge magnitude map
edge_magnitude = zeros(img_rows, img_cols);

% Initialize convolution response volume
conv_responses = zeros(img_rows, img_cols, 8);

% Perform convolution filtering for each of the 8 orientations
for orient_idx = 1:8
    % Use replicate padding to avoid border artifacts
    conv_responses(:,:,orient_idx) = imfilter(input_image, filter_stack(:,:,orient_idx), ...
                                             'conv', 'replicate');
end

% For each pixel, take the maximum response across all orientations
for row = 1:img_rows
    for col = 1:img_cols
        edge_magnitude(row, col) = max(conv_responses(row, col, :));
    end
end

end

%% Thorax segmentation with compass masks

% Preallocate binary arrays for thorax segmentation
IcatT_CM = false(volSize); % logical array for thorax mask

for k=1:volSize(3)
    Ik = volAdj(:,:,k);

    % Compute the magnitude of the edges using the compass mask method
    magnitudo = compass_edge_detector(Ik);     % Function previously defined
    threshold = 0.15 * max(max(Ik));
    Ik_max = magnitudo > threshold;

    % Fill the segmented thorax
    Ik_max = imfill(Ik_max, 'holes');

    % Removal of small artifacts
    se_open_small  = strel('disk', 2);
    Ik_max = imopen(Ik_max, se_open_small);

    % Closure of gaps in thorax segmentation
    se_close_large = strel('disk', 15);
    Ik_max = imclose(Ik_max, se_close_large);

    % Store the thorax mask in the output volume
    IcatT_CM(:,:,k) = Ik_max; 

end

%% Visualization of thorax mask overlay
% Compass mask Method

figure('Name', 'Thorax Segmentation Results', 'NumberTitle','off');
sliceViewer(volAdj, IcatT_CM);  % IcatT overlay
title('IcatT overlaid on volAdj (compass masks)');
 

%% Thorax segmentation with Canny method

% Preallocate binary arrays for thorax segmentation
IcatT_canny = false(volSize);

for k=1:volSize(3)
    Ik = volAdj(:, : , k);
    Ik = edge(Ik, 'canny');
    
    % Removal of small artifacts
    Ik = bwareaopen(Ik, 20);

    % Closure of gaps in thorax segmentation
    se_close_large = strel('disk', 30);
    Ik = imclose(Ik, se_close_large);

    % Fill the segmented thorax
    Ik = imfill(Ik, 'holes');

    % Store the thorax mask in the output volume
    IcatT_canny(:, :, k) = Ik;
end

%% Visualization of thorax mask overlay
% Canny Method

figure('Name', 'Thorax Segmentation Results', 'NumberTitle','off');
sliceViewer(volAdj, IcatT_canny);  % IcatT overlay
title('IcatT overlaid on volAdj (Canny)');

% Out of the three methods I tried, the Canny-based segmentation looks the best,
% it gives the cleanest and most consistent boundary in most frames.

%% Lung segmentation

% Preallocate binary arrays for lungs segmentation
IcatLUNG = false(volSize);
se       = strel('disk', 5);

% BW_dx and BW_sx: 3D binary masks for right and left lung respectively
% Used to compute total volume for each lung
BW_dx   = false(volSize);    
BW_sx   = false(volSize);    
midCol  = round(size(volAdj,2)/2);  

% Segmenting only the slices in witch the lungs are present
for i = 18:92

    % Remove intensity variations (h<0.8) while preserving lung structures
    % imhmax suppresses local maxima to smooth the image before thresholding
    Ik = imhmax(volAdj(:,:,i), 0.8);
    
    % Edge detection
    threshold = 0.11;           % This threshold was empirically chosen
    edges = Ik < threshold;     % Inverse thresholding: becaus lungs are air-filled, they have lower intensity than tissue
    
    % Label connected components
    L = bwlabel(edges, 8);

    % Compute region properties:
    % The Area is used to select the lungs while the Centroid is used to
    % distinguish between right and left lung
    stats = regionprops(L, 'Area', 'Centroid');
    
    if length(stats) >= 2

        % Sort Areas selected by descending Area
        [~, idx_sort] = sort([stats.Area], 'descend');

        % Skip largest region (background) and take next two (right/left lungs)
        % The background always appears as the largest connected component
        idx_top2 = idx_sort(2:3);
        top2_stats = stats(idx_top2);
        
        % Mask initialization for current slice
        BW_dx_slice = false(size(L));
        BW_sx_slice = false(size(L));
        
        % Assign regions to right/left lung based on centroid horizontal position
        for j = 1:2

            % Centroid computation for each region
            % centroid_x is the column of the Centroid
            centroid_x = top2_stats(j).Centroid(1);
            label_idx = idx_top2(j);
            
            % The region on the LEFT of the midline is stored as the RIGHT
            % lung and viceversa. 
            if centroid_x < midCol
                BW_dx_slice(L == label_idx) = true;  % Right lung (centroid_x < midline)
            else
                BW_sx_slice(L == label_idx) = true;  % Left lung (centroid_x > midline)
            end
        end

        % Morphological post-processing for each lung separately
        % Close small gaps
        BW_dx_slice = imclose(BW_dx_slice, se);
        BW_sx_slice = imclose(BW_sx_slice, se);

        % Fill internal cavities
        BW_dx_slice = imfill(BW_dx_slice, 'holes');
        BW_sx_slice = imfill(BW_sx_slice, 'holes');

        % Combine both lungs for current slice
        BW_top2 = BW_dx_slice | BW_sx_slice;
        
        % Store results in 3D volumes
        IcatLUNG(:,:,i) = BW_top2;          % Combined lung mask
        BW_dx(:,:,i)    = BW_dx_slice;      % Right lung
        BW_sx(:,:,i)    = BW_sx_slice;      % Left lung
    end
end

%% Visualization of lungs mask overlay

figure('Name', 'Lung Segmentation Results', 'NumberTitle','off');
sliceViewer(volAdj, IcatLUNG);
title('IcatLUNG regions overlaid on volAdj');

%% Right and Left Lung Volume in Pixels

% Calculate volumes of the right and left lungs by summing all non-zero
% values in the two separate masks obtained previously
fprintf('Lung Volume in Pixels\n');
fprintf('Right Lung Volume: %d pixel\n', nnz(BW_dx));
fprintf('Left Lung Volume: %d pixel\n', nnz(BW_sx));

%% Final vizualisation

[H, W, S] = size(volAdj);
 
% Preallocate RGB volume for sliceViewer (H x W x S x 3)
volFinal = zeros(H, W, S, 3);
 
for k = 1:S

    % Base grayscale
    base = volAdj(:,:,k);

    volFinal(:,:,k,1) = base;
    volFinal(:,:,k,2) = base;
    volFinal(:,:,k,3) = base;
 
    % Thorax contour (YELLOW = R + G)
    thorax_contour = bwperim(IcatT_canny(:,:,k));
    volFinal(:,:,k,1) = volFinal(:,:,k,1) + thorax_contour;
    volFinal(:,:,k,2) = volFinal(:,:,k,2) + thorax_contour;
 
    % Lung contour (MAGENTA = R + B)
    lung_contour = bwperim(IcatLUNG(:,:,k));
    volFinal(:,:,k,1) = volFinal(:,:,k,1) + lung_contour;
    volFinal(:,:,k,3) = volFinal(:,:,k,3) + lung_contour;

end
 
% Display
figure('Name','Final Visualization','NumberTitle','off');
sliceViewer(volFinal);
title('Thorax (yellow) and Lung (magenta) contours');

