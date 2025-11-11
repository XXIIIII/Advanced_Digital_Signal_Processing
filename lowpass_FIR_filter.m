clc
clear all

%% Filter Design Parameters
N = 17;                    % Filter length
k = (N-1)/2;               % Half filter order (k = 8)
delta = 0.0001;            % Convergence threshold

% Weighting factors
W_passband = 1;            % Passband weight
W_transition = 0;          % Transition band weight (not used)
W_stopband = 0.6;          % Stopband weight

% Convergence tracking variables
current_error = Inf;       % Current maximum error
previous_error = 0;        % Previous maximum error
error_history = [Inf];     % Array to store error progression

%% Initial Extreme Frequencies
% Choose k+2 = 10 extreme frequencies (avoiding transition band 0.2-0.25)
% Normalized frequencies: F = f/fs where fs = 6000 Hz
extreme_frequencies = [0.05, 0.1, 0.12, 0.15, 0.17, 0.3, 0.35, 0.4, 0.43, 0.46];

iteration_count = 0;

while (current_error - previous_error > delta) || (current_error - previous_error < 0)
    iteration_count = iteration_count + 1;
    fprintf('Iteration %d: ', iteration_count);
    
    if previous_error ~= 0
        current_error = previous_error;
    end
    
    num_extremes = k + 2;  % Number of extreme points (10)
    coefficient_matrix = zeros(num_extremes, num_extremes);
    
    % Fill cosine terms: A(i,j) = cos(2πF_i * j) for j = 0 to k
    for i = 0:(num_extremes-1)
        for j = 0:k
            coefficient_matrix(i+1, j+1) = cos(2*pi*extreme_frequencies(i+1)*j);
        end
    end
    
    % Fill weighting column: A(i, k+2) = (-1)^i / W(F_i)
    for i = 0:(num_extremes-1)
        if extreme_frequencies(i+1) <= 0.2  % Passband
            coefficient_matrix(i+1, num_extremes) = ((-1)^i) / W_passband;
        else  % Stopband
            coefficient_matrix(i+1, num_extremes) = ((-1)^i) / W_stopband;
        end
    end
    
    desired_response = zeros(num_extremes, 1);
    for i = 1:num_extremes
        if extreme_frequencies(i) <= 0.225  % Passband (with small margin)
            desired_response(i) = 1;
        else  % Stopband
            desired_response(i) = 0;
        end
    end

    solution_vector = inv(coefficient_matrix) * desired_response;
    
    syms frequency_var
    frequency_response = 0;
    for i = 0:k
        frequency_response = frequency_response + solution_vector(i+1) * cos(2*pi*i*frequency_var);
    end
    
    freq_passband = 0:0.0001:0.2;           % Passband frequencies
    freq_transition = 0.2:0.0001:0.25;      % Transition band frequencies  
    freq_stopband = 0.25:0.0001:0.5;        % Stopband frequencies
    freq_negative = -0.001:0.0001:0;        % Negative frequencies
    freq_extended = 0.5:0.0001:0.501;       % Extended frequencies 
    

    response_passband = subs(frequency_response, frequency_var, freq_passband);
    response_stopband = subs(frequency_response, frequency_var, freq_stopband);
    
    error_passband = response_passband * W_passband - W_passband;  % E = W*(H_d - R) = 1*(1 - R)
    error_transition = zeros(1, length(freq_transition));          % No error constraint in transition
    error_stopband = response_stopband * W_stopband;              % E = W*(H_d - R) = 0.6*(0 - R)
    error_negative = zeros(1, length(freq_negative));             % Padding 
    error_extended = zeros(1, length(freq_extended));             % Padding
    
    all_frequencies = [freq_negative freq_passband freq_transition freq_stopband freq_extended];
    all_errors = [error_negative error_passband error_transition error_stopband error_extended];
    
    % Find local maxima 
    [positive_peaks, positive_indices] = findpeaks(double(all_errors));
    positive_extremes = all_frequencies(positive_indices);
    [negative_peaks, negative_indices] = findpeaks(double(-all_errors));
    negative_extremes = all_frequencies(negative_indices);
    
    extreme_frequencies = [positive_extremes, negative_extremes];
    all_peak_values = [positive_peaks, negative_peaks];
    
    % Keep only required number of extremes (k+2 = 10)
    num_found_extremes = length(extreme_frequencies);
    if num_found_extremes > num_extremes
        extreme_frequencies = extreme_frequencies(1:num_extremes);
    end
    
    previous_error = max(all_peak_values);
    error_history = [error_history, previous_error];
    
    extreme_frequencies = sort(extreme_frequencies);
    
    fprintf('Max Error = %.6f\n', previous_error);
end

fprintf('\nAlgorithm converged after %d iterations\n', iteration_count);
fprintf('Final maximum error: %.6f\n', previous_error);

% Convert solution to symmetric FIR filter coefficients
filter_coefficients = zeros(1, N);
filter_coefficients(1, k+1) = solution_vector(1);  % Center coefficient h[k]

for i = 1:k
    % Symmetric coefficients: h[k+i] = h[k-i] = S[i+1]/2
    filter_coefficients(1, k+i+1) = solution_vector(i+1) / 2;
    filter_coefficients(1, k-i+1) = solution_vector(i+1) / 2;
end

%% Display Results
fprintf('\nFilter Coefficients h[n]:\n');
for i = 1:N
    fprintf('h[%2d] = %10.6f\n', i-1, filter_coefficients(i));
end

fprintf('\nError History:\n');
for i = 1:length(error_history)
    fprintf('Iteration %d: Error = %.8f\n', i-1, error_history(i));
end

%% Plot Results
figure('Position', [100, 100, 1200, 800]);

ideal_response = -(heaviside(all_frequencies - 0.225)) + 1;
actual_response = subs(frequency_response, frequency_var, all_frequencies);

subplot(2,2,1);
plot(all_frequencies, double(all_errors), 'b-', 'LineWidth', 1.5);
grid on;
title('Error Function E(F)');
xlabel('Normalized Frequency F');
ylabel('Error');
legend('Weighted Error');

subplot(2,2,2);
plot(all_frequencies, double(ideal_response), 'r--', 'LineWidth', 2);
hold on;
plot(all_frequencies, double(actual_response), 'b-', 'LineWidth', 1.5);
grid on;
title('Frequency Response Comparison');
xlabel('Normalized Frequency F');
ylabel('Magnitude');
legend('Ideal Response', 'Designed Filter', 'Location', 'best');

subplot(2,2,3);
stem(0:(N-1), filter_coefficients, 'filled');
grid on;
title('Filter Coefficients h[n]');
xlabel('Sample Index n');
ylabel('Coefficient Value');

subplot(2,2,4);
semilogy(1:length(error_history), error_history, 'ro-', 'LineWidth', 1.5);
grid on;
title('Convergence History');
xlabel('Iteration');
ylabel('Maximum Error (log scale)');

% Final combined plot 
figure('Position', [200, 200, 1000, 600]);
plot(all_frequencies, double(all_errors), 'b-', 'LineWidth', 1.5);
hold on;
plot(all_frequencies, double(ideal_response), 'r--', 'LineWidth', 2);
plot(all_frequencies, double(actual_response), 'g-', 'LineWidth', 1.5);
grid on;
title('Mini-max Lowpass FIR Filter Design Results');
xlabel('Normalized Frequency F (f/f_s)');
ylabel('Magnitude');
legend('Error Function', 'Ideal Response', 'Designed Filter', 'Location', 'best');
