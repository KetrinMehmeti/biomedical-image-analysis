%%  Exercise 3
%   1)Provide the .m code that asks for two image files OF DIFFERENT SIZE as input to be read using
%   imread. 
%   2) Once reading the second image, a check on the image size needs to be performed, and if
%   equal to the already read image, an error message needs to appear by requesting the user to
%   select an other image of different size.
%   3) After properly converting the images to grayscale (if not already), make them automatically of the
%   same size, properly adapting the smaller image to the bigger size by zeropadding.
%   4) For each image, compute its magnitude and phase, then build and visualize in the same figure two
%   antitrasformed images considering the magnitude of the first with the phase of the second one, and
%   viceversa, using the proper title to each panel of the subplot.

clear all, clc, close all;

%% 1) Prompt user to select the first image
[filename1, pathname1] = uigetfile({'*.png;*.jpg;*.jpeg;*.bmp', 'Image Files (*.png, *.jpg, *.jpeg, *.bmp)'}, 'Select the first image');
img1 = imread(fullfile(pathname1, filename1));

% Prompt user to select the second image
[filename2, pathname2] = uigetfile({'*.png;*.jpg;*.jpeg;*.bmp', 'Image Files (*.png, *.jpg, *.jpeg, *.bmp)'}, 'Select the second image');
img2 = imread(fullfile(pathname2, filename2));

%% 2) Check if the sizes of the two images are equal
% in case of equal size images an error message is displayed

while isequal(size(img1), size(img2))
    % Warning message in case the two images are of the same size
    errordlg('The selected images must be of different sizes. Please select another image.', 'Image Size Error');

    % the user is also prompted again to select the second image 
    [filename2, pathname2] = uigetfile({'*.png;*.jpg;*.jpeg;*.bmp', 'Image Files (*.png, *.jpg, *.jpeg, *.bmp)'}, 'Select the second image');
    img2 = imread(fullfile(pathname2, filename2));
end

%% 3) Grayscale conversion and size differences check

% Conversion to double
img1 = im2double(img1);
img2 = im2double(img2);

% Grayscale conversion of the first image
if size(img1,3) == 3
    img1 = rgb2gray(img1);
end

% Grayscale conversion of the second image
if size(img2,3) == 3
    img2 = rgb2gray(img2);
end


% Size Adaptation
% Determine the size of both images
[r1,c1] = size(img1);
[r2,c2] = size(img2);

% Target = maximum dimension, in oder to adapt the smaller image to the
% bigger one
Rt = max(r1,r2);
Ct = max(c1,c2);

% Original copies of images for later display
orig1 = img1; orig2 = img2;

% Computing the difference in size between the two images
dr1 = Rt - r1; dc1 = Ct - c1;
dr2 = Rt - r2; dc2 = Ct - c2;

%% 3) Size adaptation
% Calcolo padding simmetrico (pre/post) con gestione dispari

% floor --> This MATLAB function rounds each element of X to the nearest integer
% less than or equal to that element.

% ceil --> This MATLAB function rounds each element of X to the nearest integer
% greater than or equal to that element.

% This step ensures odd differences in size are handled
% For Example using as a test the two images 'image82.jpg' (593 x 576) and
% 'volto.jpg' (1024 x 1024), the difference in the number of rows is equal
% to 531, so in order to center the zero-padded image as much as possible
% the code applies a zero padding equal to 215 on top and 216 on the bottom

% It would be handled similarly if the difference in the number of columns
% were to be odd 
pre1  = [floor(dr1/2), floor(dc1/2)];
post1 = [ceil(dr1/2),  ceil(dc1/2)];

pre2  = [floor(dr2/2), floor(dc2/2)];
post2 = [ceil(dr2/2),  ceil(dc2/2)];

% Zero padding to the smaller image

% Note: the any function has been used in oder to ensure that the two images
% obtained are of the same size even if only one dimension in one of the
% two images is bigger than the other (example: img1 [1024 x 500], img2 [1024 x 1024])
if any([dr1 dc1] > 0)
    img1 = padarray(img1, pre1, 0, 'pre');
    img1 = padarray(img1, post1, 0, 'post');
end

if any([dr2 dc2] > 0)
    img2 = padarray(img2, pre2, 0, 'pre');
    img2 = padarray(img2, post2, 0, 'post');
end

% Messages to the user to inform them on which image has been zero-padded
% and how
if any([dr1 dc1] > 0)
    fprintf('Image 1 zero-padded [%d x %d] -> top:%d, bottom:%d, left:%d, right:%d\n', ...
        Rt, Ct, pre1(1), post1(1), pre1(2), post1(2));
else
    fprintf('Image 1: NO zero-padding (already [%d x %d]).\n', r1, c1);
end

if any([dr2 dc2] > 0)
    fprintf('Image 2 zero-padded [%d x %d] -> top:%d, bottom:%d, left:%d, right:%d\n', ...
        Rt, Ct, pre2(1), post2(1), pre2(2), post2(2));
else
    fprintf('Image 2: No zero-padding (already [%d x %d]).\n', r2, c2);
end

%% 4) Magnitude and Phase computation
% Compute 2-D FFT and shift zero-frequency component to the center

% IMAGE 1
F1  = fft2(img1);        % 2-D Fourier transform 
Fc1 = fftshift(F1);      % center the zero-frequency component 
% Build magnitude (log-compressed) and phase
Sm1 = log(1+abs(Fc1));   % log compression for dynamic range 
Sp1 = angle(Fc1);        % phase in radians in [-pi, pi] 

% IMAGE 2
F2  = fft2(img2);          % 2-D Fourier transform 
Fc2 = fftshift(F2);        % center the zero-frequency component 
% Build magnitude (log-compressed) and phase for image 2
Sm2 = log(1 + abs(Fc2));   % log compression for dynamic range 
Sp2 = angle(Fc2);          % phase in radians in [-pi, pi]

% Visualization: magnitude and phase 

% IMAGE 1
figure('Name','2-D FFT: Magnitude and Phase');
subplot(2,2,1);
imshow(Sm1, []); title('Magnitude Spectrum of img1 (log scale)');     % magnitude view of img1
colormap(jet); 
colorbar;
subplot(2,2,2);
imshow(Sp1, []); title('Phase Spectrum of img1 (radians)');           % phase view of img1
colormap(jet); 
colorbar; 

% IMAGE 2
subplot(2,2,3);
imshow(Sm2, []); title('Magnitude Spectrum of img2 (log scale)');     % magnitude view of img2
colormap(jet); 
colorbar;
subplot(2,2,4);
imshow(Sp2, []); title('Phase Spectrum of img2 (radians)');           % phase view of img2
colormap(jet); 
colorbar;

%% 4) Antitransformed images

% Considering the absolute value of the magnitute 
% (Sp1 and Sp2 already defined as angle(Fc1) and angle(Fc2))
A1 = abs(Fc1);  
A2 = abs(Fc2);

% Swap magnitude/phase e ifft

% Note 1: ifftshift has been used to reverse the fftshift done in the
% previous section

% Note 2: real has been used to avoid the Warning message: 
% "Warning: Displaying real part of complex input."
R12 = real(ifft2(ifftshift(A1 .* exp(1i*Sp2))));
R21 = real(ifft2(ifftshift(A2 .* exp(1i*Sp1))));

% Normalization
R12v = im2double(R12);
R21v = im2double(R21);

% Figure with 4 subplots: in the first row the two original images are shown
% in the second row the reconstructed images with the phase swap are shown 
figure('Name','Magnitude/Phase swap - reconstructions','NumberTitle','off');
subplot(2,2,1); imshow(img1,[]);  title('img1 (spatial)');
subplot(2,2,2); imshow(img2,[]);  title('img2 (spatial)');
subplot(2,2,3); imshow(R12v,[]); title('|img1| + \angle img2 (ifft2)');
subplot(2,2,4); imshow(R21v,[]); title('|img2| + \angle img1 (ifft2)');
