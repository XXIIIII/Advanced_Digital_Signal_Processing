%% Discrete Hilbert Transform Filter Design using Frequency Sampling Method
% - Filter length: N = 2k+1 = 33 points (k = 16)

clc
clear all

k = 16;                    % Half filter order
N = 2*k + 1;              % Total filter length (33 points)

%% Step 1: Frequency Domain Sampling

frequency_response = zeros(1, N);

frequency_response(1, 2) = -0.9*1j;           % H[1] = -0.9j 
frequency_response(1, N) = 0.9*1j;            % H[N-1] = +0.9j 

frequency_response(1, k+1) = -0.7*1j;         % H[k] = -0.7j 
frequency_response(1, k+2) = 0.7*1j;          % H[k+1] = +0.7j 

frequency_response(1, 3:k) = -1j;             % H[2:k-1] = -j (positive frequencies)
frequency_response(1, k+3:N-1) = 1j;         % H[k+2:N-2] = +j (negative frequencies)

%% Step 2: Inverse FFT to get Time Domain Response
time_response_raw = ifft(frequency_response);

%% Step 3: Circular Shift for Causal Filter

impulse_response = zeros(1, N);

% Move the last k samples to the beginning
impulse_response(1, 1:k) = time_response_raw(1, N-k+1:N);

% Move the first N-k samples to the end
impulse_response(1, k+1:N) = time_response_raw(1, 1:N-k);

%% Step 4: Plot Impulse Response
figure('Position', [100, 100, 1000, 600]);

subplot(2, 1, 1);
stem(-k:k, real(impulse_response), 'filled', 'LineWidth', 1.5);
grid on;
title('Hilbert Transform Filter - Real Part of Impulse Response', 'FontSize', 14);
xlabel('Sample Index n', 'FontSize', 12);
ylabel('Real Part h_{real}[n]', 'FontSize', 12);

subplot(2, 1, 2);
stem(-k:k, imag(impulse_response), 'filled', 'LineWidth', 1.5);
grid on;
title('Hilbert Transform Filter - Imaginary Part of Impulse Response', 'FontSize', 14);
xlabel('Sample Index n', 'FontSize', 12);
ylabel('Imaginary Part h_{imag}[n]', 'FontSize', 12);

%% Step 5: Calculate and Plot Frequency Response

normalized_frequencies = 0:0.0001:1;          % Normalized frequency range [0, 1]
num_freq_points = length(normalized_frequencies);
frequency_magnitude = zeros(1, num_freq_points);
frequency_phase = zeros(1, num_freq_points);

for freq_idx = 1:num_freq_points
    current_freq = normalized_frequencies(freq_idx);
    complex_response = 0;
    
    % Sum over all filter coefficients
    for sample_idx = 1:N
        n = sample_idx - k - 1;  % Convert to centered index: n ∈ [-k, k]
        complex_response = complex_response + impulse_response(sample_idx) * ...
                          exp(-2*pi*1j * n * current_freq);
    end
    
    frequency_magnitude(freq_idx) = abs(complex_response);
    frequency_phase(freq_idx) = angle(complex_response);
end


%% Plot Frequency Response
figure('Position', [200, 200, 1200, 800]);

% Plot magnitude response
subplot(3, 1, 1);
plot(normalized_frequencies, frequency_magnitude, 'b-', 'LineWidth', 2);
grid on;
title('Hilbert Transform Filter - Magnitude Response', 'FontSize', 14);
xlabel('Normalized Frequency f/f_s', 'FontSize', 12);
ylabel('|H(f)|', 'FontSize', 12);
ylim([0, 1.5]);

% Plot phase response
subplot(3, 1, 2);
plot(normalized_frequencies, frequency_phase*180/pi, 'r-', 'LineWidth', 2);
grid on;
title('Hilbert Transform Filter - Phase Response', 'FontSize', 14);
xlabel('Normalized Frequency f/f_s', 'FontSize', 12);
ylabel('Phase (degrees)', 'FontSize', 12);

% Plot imaginary part of frequency response (main characteristic)
subplot(3, 1, 3);
imaginary_response = zeros(1, num_freq_points);
for freq_idx = 1:num_freq_points
    current_freq = normalized_frequencies(freq_idx);
    complex_response = 0;
    
    for sample_idx = 1:N
        n = sample_idx - k - 1;
        complex_response = complex_response + impulse_response(sample_idx) * ...
                          exp(-2*pi*1j * n * current_freq);
    end
    
    imaginary_response(freq_idx) = imag(complex_response);
end

plot(normalized_frequencies, imaginary_response, 'g-', 'LineWidth', 2);
grid on;
title('Hilbert Transform Filter - Imaginary Part of Frequency Response', 'FontSize', 14);
xlabel('Normalized Frequency f/f_s', 'FontSize', 12);
ylabel('Imag{H(f)}', 'FontSize', 12);
