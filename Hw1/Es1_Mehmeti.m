%% Exercize 1

%   Dr Crazy needs a software to perform the 2-D FFT of a biomedical image In order to provide him
%   with the desired tool, provide the m-code that:
%   a) allow the user, by using the proper I-O interface, to select the file from a folder containing it
%   and load it for further processing.
%   b) from the selected file, show its content and give the user the option to increase the contrast
%   by performing histogram stretching with optimal parameters, or histogram equalization
%   c) visualize the results and, once the user is satisfied with the resulting enhancement, ask him
%   for the size of the zero padding to be added to the image while performing FFT.
%   d) Perform the FFT command, and appropriately visualize magnitude and phase.
%   In the .m file, use proper comments to delimit these points in the code.
%   VERY IMPORTANT FOR EVALUATION: Let the user understand what you require from him/her
%   using the proper messages in the I/O interfaces.

clc; clear; close all;

%% File Selection Procedure
% Display a welcome message to guide the user through the biomedical image selection process.
disp('Welcome Dr. Crazy! Please select the biomedical image file...');

% Open a file selection dialog allowing the user to choose either a conventional image file or a MATLAB MAT-file,
% thus accommodating both general image formats and structured biomedical datasets.
[filename, pathname] = uigetfile({'*.png;*.jpg;*.tif;*.bmp;*.mat', 'Image or MAT Files'}, ...
    'Select an image for processing');

% Check whether the user canceled the file selection dialog.
% If the selection is canceled, notify the user and exit the program to prevent further execution without input data.
if isequal(filename,0)
    disp('No file selected. Exiting...');
    return;
end

% Image Loading Depending on File Format
% Determine if the selected file is a MATLAB MAT-file.
if endsWith(filename, '.mat')
    % Load the entire content of the MAT-file into a structured data variable.
    data = load(fullfile(pathname, filename));
    % Retrieve the list of variable names stored in the MAT-file.
    fields = fieldnames(data);

    % Display the available fields in the MAT-file, providing both the variable names and their sizes.
    disp('Fields found in the MAT file:');
    for i = 1:numel(fields)
        sz = size(data.(fields{i}));
        disp([num2str(i), ': ', fields{i}, ' [', num2str(sz), ']']);
    end

    % Initialize a flag to track valid image variable selection.
    valid_selection = false;
    % Loop until the user selects a valid image variable.
    while ~valid_selection
        % Prompt the user to select which field should be interpreted as the image,
        % ensuring interactive and unambiguous extraction of the relevant matrix.
        idx = input('Select the field number corresponding to the image: ');

        % Validate the input index range.
        if idx >= 1 && idx <= numel(fields)
            candidate = data.(fields{idx});
            % Check if candidate is numeric, 2D and is not empty,
            % which are conditions for valid image data.
            if isnumeric(candidate) && (ndims(candidate) == 2) && ~isempty(candidate)
                % Mark the selection as valid, assign the image data,
                % and confirm the successful loading to the user.
                valid_selection = true;
                img = candidate;
                disp(['Loaded image from field: ', fields{idx}]);
            else
                % Inform the user about invalid selection and prompt again.
                disp('Selected field is not a valid image (numeric 2D or 3D array). Please select again.');
            end
        else
            % Inform the user about invalid index input and prompt again.
            disp('Invalid selection index. Please try again.');
        end
    end
else
    % In case of a standard image file, read the image directly into memory using imread.
    img = imread(fullfile(pathname, filename));
    disp(['Loaded image: ', filename]);
end

% Grayscale Conversion (If Necessary)
% If the selected image is in color (has three color channels),
% convert it to a grayscale representation. 
if size(img,3) == 3
    img = rgb2gray(img);
end

%% Visualization of the Original Image and Histogram

figure('Name','Original Image and Histogram');

% Subplot 1: Show the original image
subplot(1,2,1);
imshow(img, []);
title('Original Image');

% Subplot 2: Show the histogram of the image intensities
subplot(1,2,2);
imhist(img);
title('Original Histogram');


%% b) CONTRAST ENHANCEMENT OPTIONS
% Define the enhancement options to present to the user
opts = {'Histogram Stretching (stretchlim + imadjust)', ...
        'Histogram Equalization (histeq, nlev=64)', ...
        'No enhancement'};

% listdlg opens a modal dialog with a list of strings and returns the index
% of the selected item.
[idx, ok] = listdlg('PromptString', {'Choose contrast enhancement method you want to apply to the image:', ...
                                     'Select one option and press OK.'}, ...
                    'SelectionMode', 'single', ...
                    'ListString', opts, ...
                    'ListSize', [320 150], ...
                    'Name', 'Contrast Enhancement');

% Handle cancel or empty selection 
if ~ok || isempty(idx)
    % If user cancels, default to no enhancement to keep pipeline consistent
    idx = 3;
end

% Normalize input image to [0,1] 
% this MATLAB function converts the matrix A to a grayscale image I that
% contains values in the range 0 (black) to 1 (white).
I = mat2gray(img);

switch idx
    case 1
        % Histogram Stretching with limits (1% per side)
        lim = stretchlim(I, [0.01 0.99]);
        img_enh = imadjust(I, lim, []);
        method  = 'Histogram Stretching (stretchlim + imadjust)';
    case 2
        % Histogram Equalization with a limited number of output levels
        nlev = 64;  
        img_enh = histeq(I, nlev);
        method  = sprintf('Histogram Equalization (histeq, nlev=%d)', nlev);
    otherwise
        % No enhancement
        img_enh = I;
        method  = 'No enhancement';
end

% Side-by-side comparison (2x2): original/enhanced images and histograms
I0 = I;
I1 = img_enh;

% In the first row of this subplot the original and Enhanced images are
% shown for visual comparison

% In the second row the two Histograms are shown: the original and the
% histogram obtained after enhancement
figure('Name','Original vs Enhanced: Images and Histograms');
subplot(2,2,1); imshow(I0, []); title('Original Image');
subplot(2,2,2); imshow(I1, []); title(['Enhanced Image - ' method]);
subplot(2,2,3); imhist(I0);     title('Original Histogram');
subplot(2,2,4); imhist(I1);     title('Enhanced Histogram');

%% Ask user satisfaction
% In this section the user has the possibility to change their initial
% decision in case of unsatisfactory results or, alternatively, to apply
% contrast enhancement in case their first decision was to apply no
% enhancement at all

answer = questdlg('Are you satisfied of the contrast enhancment abtained?', ...
                  'Confirm', ...
                  'Yes','No','Yes');

% Default final outputs
img_enh_final = img_enh;
method_final  = method;

if strcmp(answer,'No')
    % Apply the alternative enhancement
    switch idx
        case 1  % If Stretching was used, switch to Equalization
            nlev = 64;
            img_enh_alt = histeq(I, nlev);
            method_alt  = sprintf('Histogram Equalization (histeq, nlev=%d)', nlev);
        case 2  % If Equalization was used, switch to Stretching
            lim = stretchlim(I, [0.01 0.99]);
            img_enh_alt = imadjust(I, lim, []);
            method_alt  = 'Histogram Stretching (stretchlim + imadjust)';
        otherwise  % If No enhancement was used, ask which enhancement to apply
            [altIdx, ok2] = listdlg('PromptString', {'No enhancement has been applied.', ...
                                                     'Select a method:'}, ...
                                    'SelectionMode', 'single', ...
                                    'ListString', opts(1:2), ...
                                    'ListSize', [320 150], ...
                                    'Name', 'Seleziona miglioramento');
            if altIdx == 1
                lim = stretchlim(I, [0.01 0.99]);
                img_enh_alt = imadjust(I, lim, []);
                method_alt  = 'Histogram Stretching (stretchlim + imadjust)';
            else
                nlev = 64;
                img_enh_alt = histeq(I, nlev);
                method_alt  = sprintf('Histogram Equalization (histeq, nlev=%d)', nlev);
            end
    end

    % Update final outputs and show comparison for the alternative
    img_enh_final = img_enh_alt;
    method_final  = method_alt;

    % In the first row of this subplot the original and Enhanced images are
    % shown for visual comparison

    % In the second row the two Histograms are shown: the original and the
    % histogram obtained after enhancement
    figure('Name','Alternative Enhancement Applied: Images and Histograms');
    subplot(2,2,1); imshow(I0, []); title('Original Image');
    subplot(2,2,2); imshow(img_enh_final, []); title(['Enhanced Image - ' method_final]);
    subplot(2,2,3); imhist(I0);     title('Original Histogram');
    subplot(2,2,4); imhist(img_enh_final);     title('Enhanced Histogram');
end

%% c) ZERO PADDING INPUT
% Ask the user for zero padding size (nonnegative integer)
prompt = 'Enter the size of zero padding (e.g., 0, 50, 100): ';
pad = input(prompt); 

% Validate input and default to 0 if invalid
if isempty(pad) || ~isscalar(pad) || ~isfinite(pad) || pad < 0
    pad = 0;
else
    pad = round(pad);
end

% Ensure double precision in [0,1] 
I = im2double(img_enh_final);  % enhanced image confirmed in step b) 

% Apply symmetric zero padding on all sides
Ipad = padarray(I, [pad pad], 0, 'both');  % zero padding before/after rows and cols 

%% d) 2-D FFT magnitude and phase visualization
% Compute 2-D FFT and shift zero-frequency component to the center
F  = fft2(Ipad);       % 2-D Fourier transform 
Fc = fftshift(F);      % center the zero-frequency component 

% Build magnitude (log-compressed) and phase
Sm = log(1+abs(Fc));   % log compression for dynamic range 
Sp = angle(Fc);        % phase in radians in [-pi, pi] 

% Visualization:  magnitude and phase 
figure('Name','2-D FFT: Magnitude and Phase');
subplot(1,2,1);
imshow(Sm, []); title('Magnitude Spectrum (log scale)');     % magnitude view
colormap(jet); 
colorbar;
subplot(1,2,2);
imshow(Sp, []); title('Phase Spectrum (radians)');           % phase view
colormap(jet); 
colorbar; 

 
