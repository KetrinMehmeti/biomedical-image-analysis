%% Exercise 4
%  In the file h4_2025.mat there are 4 images corrupted by noise. For each image, identify
%  the type of affecting noises and the ALL the relevant parameters that describe them.
%  Return a report with a description of your process and results.

clc, clear all, close all
%% Open the four images
load('h4_2025.mat'); % Load the .mat file containing the images

%% Plot the four images to assess the type of noise visually
figure;
subplot(2, 2, 1)
imshow(img0, []);
title('img0: Sinusoidal noise')

subplot(2, 2, 2)
imshow(img1, []);
title('img1: Gaussian noise')

subplot(2, 2, 3)
imshow(img2, []);
title('img2: Salt & Pepper and Sinusoidal noise')

subplot(2, 2, 4)
imshow(img3, []);
title('img3: Salt & Pepper')

%% Convert to double


% img1 = im2double(img1); --> NOt converting this image to double because
% if I do the Gaussian noise resulting is close to zero
I2=img2; % per non averlo double dopo
img2 = im2double(img2);
img3 = im2double(img3);


%% Salt & Pepper (img2 and img3)

% Calculation of the Salt & Pepper noise density for images img2 and img3
% The density is defined as the proportion of pixels with values 0 or 1
% (representing the "salt" and "pepper" noise) relative to the total number of pixels in the image

d2 = (sum(img2(:) == 0) + sum(img2(:) == 1)) / numel(img2);  % Noise density in img2
d3 = (sum(img3(:) == 0) + sum(img3(:) == 1)) / numel(img3);  % Noise density in img3

% Display of the results: the calculated density represents the percentage of pixels affected by noise.
% The obtained values are consistent with expectations, confirming that the density of noise 
% in img2 (d2=0.023151) is lower than the density in img3 (d3=0.077373).
fprintf('The density of the Salt & Pepper noise for the second image (img2) is: %.6f\n', d2);
fprintf('The density of the Salt & Pepper noise for the third image (img3) is: %.6f\n', d3);

%% Gaussian Noise (img1)

% Define a 3x3 averaging (mean) filter kernel.
% Each element is 1/9 so the kernel computes the local average.
window = ones(3,3) * 1/9;

% Apply the filter to the original image 'img1'.
% "same" keeps the output the same size as the input.
% "conv" specifies convolution.
img1_filtered = imfilter(img1, window, "same", "conv");

% Estimate the noise by subtracting the filtered (smoothed) image
% from the original image. The result contains primarily high-frequency
% components which we treat as the noise estimate.
estimated_noise = img1 - img1_filtered;

% Compute the mean of the estimated noise.
% mean(estimated_noise(:)) collapses the matrix into a vector and returns its mean.
mean_noise = mean(estimated_noise(:));

% Compute the sample variance of the estimated noise.
% We use the unbiased estimator with (N-1) in the denominator:
% sum((x - mean)^2) / (N - 1)
var_noise = sum((estimated_noise(:) - mean_noise).^2) / (numel(estimated_noise) - 1);
std_noise = sqrt(var_noise);

% Display the results with 4 decimal places.
fprintf('The mean of the Gaussian noise is: %.4f\n', mean_noise);
fprintf('The variance of the Gaussian noise is: %.4f\n', var_noise);
fprintf('The Standard Deviation of the Gaussian noise is: %.4f\n', std_noise);

%% Sinusoidal noise (img0 and img2)
I0 = img0;
F0 = fft2(double(I0));
F0_shift = fftshift(F0);
spectrum0=abs(F0_shift);


% I2 = img2;
F2 = fft2(double(I2));
F2_shift = fftshift(F2);
spectrum2=abs(F2_shift);

%%
figure;

figure;
subplot(1, 2, 1)
imshow(spectrum0, []);
title('Fourier spectrum of img0');
colormap ('jet');
colorbar;

subplot(1, 2, 2)
imshow(spectrum2, []);
title('Fourier spectrum of img2');
colormap ('jet');
colorbar;

%% Amplitude, angle and frequency computation of sinusoidal noise in img0

%% img0

% Coordinates of the zero frequency
x_center = size(I2,2)/2 + 1;  
y_center = size(I2,1)/2 + 1;  

% coordinates of the peak (obtained manually through visual inspetion of the spectrum)
x_peak0 = 517;  
y_peak0 = 520;  

% Spatial frequency computation
fx0 = (x_peak0 - x_center)/size(I2,2);  % in x (cycles/pixel)
fy0 = (y_peak0 - y_center)/size(I2,1);  % in y (cycles/pixel)

% Sinusoid amplitude

% NOTE: In MATLAB, when you access a matrix element as spectrum(y_peak, x_peak), 
% the first index always refers to the row (vertical direction, y) 
% and the second index refers to the column (horizontal direction, x).
A_peak0 = spectrum0(y_peak0, x_peak0);  
A_sin0 = 2 * A_peak0 / numel(I0);     % where I0=img0

% Angle
theta0 = atan(fy0/fx0) * (180/pi);  % angle in degrees with respect to the x axis

% Visualize the results
fprintf('Spatial frequency fx in img0: %.4f cycles/pixel\n', fx0);
fprintf('Spatial frequency fy in img0: %.4f cycles/pixel\n', fy0);
fprintf('Amplitude of the sinusoidal noise in img0: %.4f\n', A_sin0);
fprintf('Orientation angle of the sinusoidal noise in img0: %.2f degrees\n', theta0);

%% img2 

% coordinates of the peak (obtained manually through visual inspetion of the spectrum)
x_peak2 = 516;  
y_peak2 = 513;  

% Spatial frequency computation
fx2 = (x_peak2 - x_center)/size(I2,2);  % in x (cycles/pixel)
fy2 = (y_peak2 - y_center)/size(I2,1);  % in y (cycles/pixel)

% Sinusoid amplitude
% NOTE: In MATLAB, when you access a matrix element as spectrum2(y_peak, x_peak), 
% the first index always refers to the row (vertical direction, y) 
% and the second index refers to the column (horizontal direction, x).
A_peak2 = spectrum2(y_peak2, x_peak2);  
A_sin2 = 2 * A_peak2 / numel(I2);     % where I0=img0

% Angle
theta2 = atan(fy2/fx2) * (180/pi);  % angle in degrees with respect to the x axis

% Visualize the results
fprintf('Spatial frequency fx in img2: %.4f cycles/pixel\n', fx2);
fprintf('Spatial frequency fy in img2: %.4f cycles/pixel\n', fy2);
fprintf('Amplitude of the sinusoidal noise in img2: %.4f\n', A_sin2);
fprintf('Orientation angle of the sinusoidal noise in img2: %.2f degrees\n', theta2);