% CDMA Multi-User Signal Generation in MATLAB with Dynamic User Input

% Clear the workspace and command window
clear; clc;

%% Input Parameters

% Prompt the user to enter the number of users
num_users = input('Enter the number of users: ');
% Prompt the user to enter the number of bits in data for each user
num_data_bits = input('Enter the number of data bits for each user: ');

% Prompt the user to enter the length of the PN sequence
pn_length = input('Enter the length of the PN sequence (e.g., 4): ');

% Initialize data and PN sequences for all users
data_bits = cell(1, num_users);    % Cell array to hold data bits for each user
pn_sequences = cell(1, num_users); % Cell array to hold PN sequences for each user

% Loop to input data bits and PN sequences for each user
for user = 1:num_users
    fprintf('--- User %d ---\n', user);
    
    % Get data bits for the user (input as an array, e.g., [1 0])
    data_bits{user} = input(sprintf('Enter %d data bits for this user (e.g., [1 0 ...]): ', num_data_bits));
    
    % Get PN sequence for the user (input PN sequence based on the user-specified length)
    pn_sequences{user} = input(sprintf('Enter the %d-bit PN sequence for this user (e.g., [1 -1 1 -1 ...]): ', pn_length));
end

%% Convert Data Bits to Bipolar Format (1 -> +1, 0 -> -1)
bipolar_data = cell(1, num_users);  % Cell array to hold bipolar format of data for each user

for user = 1:num_users
    bipolar_data{user} = 2 * data_bits{user} - 1;  % Convert binary to bipolar
end

%% Spread the Data for Each User using the Corresponding PN Sequence

% Initialize the spread signal for each user
spread_signals = cell(1, num_users);

% Spread the data for each user
for user = 1:num_users
    spread_signals{user} = [];  % Initialize spread signal for this user
    for i = 1:length(bipolar_data{user})
        spread_signals{user} = [spread_signals{user}, bipolar_data{user}(i) * pn_sequences{user}];
    end
end

%% Generate the Composite Signal by Adding All Spread Signals

% Initialize the composite signal with zeros
composite_signal = zeros(1, length(spread_signals{1}));

% Add all users' spread signals to form the composite signal
for user = 1:num_users
    composite_signal = composite_signal + spread_signals{user};
end

%% Display and Plot Results in Separate Figures for Each User

for user = 1:num_users
    figure;
    
    % Plot the input data for each user
    subplot(2, 1, 1);  % Create a subplot for input data
    stem(data_bits{user}, 'filled');
    title(sprintf('Input Data for User %d', user));
    xlabel('Bit Index');
    ylabel('Bit Value');
    grid on;
    
    % Plot the spread signal for each user in a subplot
    subplot(2, 1, 2);  % Create a subplot for spread signal
    stem(spread_signals{user}, 'filled');
    title(sprintf('Spread Signal for User %d', user));
    xlabel('Sample Index');
    ylabel('Amplitude');
    grid on;
end

%% Display the Composite Signal

figure;
stem(composite_signal, 'filled');
title(sprintf('Composite CDMA Signal (%d Users, %d-bit PN Sequence)', num_users, pn_length));
xlabel('Sample Index');
ylabel('Amplitude');
grid on;

%% Additional Information
% Print the amplitudes of the composite signal
disp('Amplitudes of the Composite Signal:');
disp(composite_signal);