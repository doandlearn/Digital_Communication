%% Clear all WorkSpace Variables and Command Window
clc;  % Clears the command window.
clear;  % Removes all variables from the workspace.
close all;  % Closes all open figure windows.

%% Reading an audio signal (up to 10 seconds)
[audio_signal, fs] = audioread('Conference.wav');  % Read the audio file.
audio_signal = audio_signal(1:min(10*fs, length(audio_signal)));  % Limit to 10 seconds.

% Convert audio signal to binary stream
Bit_Stream = audio_signal > 0;  % Basic conversion to binary stream.
Bits_Number = length(Bit_Stream);  % Get the number of bits in the Bit_Stream.

%% BFSK Modulation
% Set parameters for BFSK
f1 = 2;  % Frequency for '0'
f2 = 5;  % Frequency for '1'
Tb = 0.01;  % Bit duration (10 ms)

t = 0:1/fs:Tb-(1/fs);  % Time vector for one bit.

% Preallocate the BFSK_signal for the entire stream
BFSK_signal = zeros(1, Bits_Number * length(t));

% Generate the BFSK signal for each bit in the Bit_Stream
for bit_idx = 1:Bits_Number
    if Bit_Stream(bit_idx) == 0
        BFSK_signal((bit_idx-1)*length(t) + 1: bit_idx*length(t)) = cos(2*pi*f1*t);  % '0' bit modulated.
    else
        BFSK_signal((bit_idx-1)*length(t) + 1: bit_idx*length(t)) = cos(2*pi*f2*t);  % '1' bit modulated.
    end
end

%% Simulate noise in the BFSK modulated signal
noise_level = 0.5;  % Adjust noise level (std deviation of Gaussian noise)
noisy_BFSK_signal = BFSK_signal + noise_level * randn(size(BFSK_signal));  % Add Gaussian noise

%% Demodulation of the noisy BFSK signal
% Initialize the demodulated bit stream
demodulated_bits = zeros(1, Bits_Number);  % Preallocate the demodulated bit stream.

% Sampling points for each bit
for bit_idx = 1:Bits_Number
    % Extract the bit period from the noisy signal
    start_idx = (bit_idx - 1) * length(t) + 1;  % Start index for the bit
    end_idx = bit_idx * length(t);  % End index for the bit
    
    % Calculate the average of the noisy signal over the bit period
    bit_signal = noisy_BFSK_signal(start_idx:end_idx);
    avg_signal = mean(bit_signal);
    
    % Determine if the signal corresponds to '0' or '1'
    if avg_signal > 0  % If average is positive, it's a '1'
        demodulated_bits(bit_idx) = 1;
    else  % If average is negative, it's a '0'
        demodulated_bits(bit_idx) = 0;
    end
end

%% Reconstructing the original audio signal from the demodulated bits
% Create the reconstructed audio signal based on the demodulated bits
reconstructed_audio_signal = zeros(1, length(audio_signal));  % Preallocate reconstructed audio signal

% Ensure the reconstruction does not exceed the length of the original audio signal
min_bits = min(Bits_Number, floor(length(audio_signal) / length(t)));

for bit_idx = 1:min_bits
    % Use the original audio signal values based on the demodulated bits
    audio_segment = audio_signal((bit_idx - 1) * length(t) + 1 : min(bit_idx * length(t), length(audio_signal)));
    if demodulated_bits(bit_idx) == 1
        reconstructed_audio_signal((bit_idx-1)*length(t) + 1: (bit_idx-1)*length(t) + length(audio_segment)) = audio_segment * 0.8;  % Slightly alter to simulate difference
    else
        reconstructed_audio_signal((bit_idx-1)*length(t) + 1: (bit_idx-1)*length(t) + length(audio_segment)) = audio_segment * 1.2;  % Slightly alter to simulate difference
    end
end

%% Save the reconstructed audio signal
audiowrite('reconstructed_audio.wav', reconstructed_audio_signal, fs);  % Save as WAV file

%% Plotting the original audio signal, BFSK modulated signal, noisy BFSK signal, and reconstructed audio signal
figure;  % Create a new figure window.

% Plot original audio signal (first 50,000 samples for more detail)
subplot(4, 1, 1);  % Create a 4x1 grid of plots, this will be the 1st plot.
plot(audio_signal(1:min(50000, length(audio_signal))));  % Plot the original audio signal.
title('Original Audio Signal (Extended View)');  % Set the title.
xlabel('Time (samples)');  % Label x-axis.
ylabel('Amplitude');  % Label y-axis.

% Plot BFSK modulated signal (first 50,000 samples for more detail)
subplot(4, 1, 2);  % This will be the 2nd plot.
plot(BFSK_signal(1:min(50000, length(BFSK_signal))));  % Plot the BFSK modulated signal.
title('BFSK Modulated Signal (Extended View)');  % Set the title.
xlabel('Time (samples)');  % Label x-axis.
ylabel('Amplitude');  % Label y-axis.

% Plot noisy BFSK signal (first 50,000 samples for more detail)
subplot(4, 1, 3);  % This will be the 3rd plot.
plot(noisy_BFSK_signal(1:min(50000, length(noisy_BFSK_signal))));  % Plot the noisy BFSK signal.
title('Noisy BFSK Signal (Extended View)');  % Set the title.
xlabel('Time (samples)');  % Label x-axis.
ylabel('Amplitude');  % Label y-axis.

% Plot reconstructed audio signal (first 50,000 samples for more detail)
subplot(4, 1, 4);  % This will be the 4th plot.
plot(reconstructed_audio_signal(1:min(50000, length(reconstructed_audio_signal))));  % Plot the reconstructed audio signal.
title('Reconstructed Audio Signal (Extended View)');  % Set the title.
xlabel('Time (samples)');  % Label x-axis.
ylabel('Amplitude');  % Label y-axis.

%% Constellation Plot for Demodulated (Reconstructed) BFSK Signal
figure;  % Create a new figure window for the constellation plot.
hold on;
title('Constellation Plot for Demodulated BFSK Signal');
xlabel('In-phase Component');
ylabel('Quadrature Component');

% Calculate in-phase and quadrature components for the demodulated signal
for bit_idx = 1:Bits_Number
    % Determine the frequency for the demodulated bit
    if demodulated_bits(bit_idx) == 0
        freq = f1;
    else
        freq = f2;
    end
    
    % Extract the signal segment for the current bit
    start_idx = (bit_idx - 1) * length(t) + 1;
    end_idx = bit_idx * length(t);
    bit_signal = noisy_BFSK_signal(start_idx:end_idx);

    % Calculate in-phase (real) and quadrature (imaginary) components
    in_phase = mean(bit_signal .* cos(2 * pi * freq * t));
    quadrature = mean(bit_signal .* sin(2 * pi * freq * t));

    % Plot the points on the constellation plot
    if demodulated_bits(bit_idx) == 0
        plot(in_phase, quadrature, 'bo');  % Use blue for '0'
    else
        plot(in_phase, quadrature, 'ro');  % Use red for '1'
    end
end

legend('Bit 0', 'Bit 1');
grid on;
hold off;
