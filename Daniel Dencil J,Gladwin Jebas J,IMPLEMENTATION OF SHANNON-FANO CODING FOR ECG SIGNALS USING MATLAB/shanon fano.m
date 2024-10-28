
load('data.mat');

sampling_frequency = 360;
time_axis = (0:length(data)-1) / sampling_frequency;
plot(time_axis, data);
xlabel('Time (seconds)');
ylabel('Voltage (mV)');
title('ECG Signal');
grid on;

% Unique symbols and their probabilities
symbols = unique(data);
symbols = reshape(symbols, [], 1); % Ensure symbols is a column vector
bin_edges = [symbols; max(symbols) + 1];

% Calculate probabilities based on the occurrence of each symbol
probabilities = histcounts(data, bin_edges) / numel(data);

% Create nodes for each symbol (each node contains symbol and its probability)
nodes = cell(1, numel(symbols));
for i = 1:numel(symbols)
    nodes{i} = struct('symbol', symbols(i), 'probability', probabilities(i));
end

% Sort nodes by probability in descending order
[~, sort_idx] = sort(cellfun(@(x) x.probability, nodes), 'descend');
nodes = nodes(sort_idx);

% Generate Shannon-Fano codes using containers.Map to avoid issues with field names
function codes = shannon_fano_codes(nodes)
    codes = containers.Map('KeyType', 'double', 'ValueType', 'char');
    generate_codes(nodes, '', codes);
end

function generate_codes(nodes, code, codes)
    if numel(nodes) == 1
        % If there's only one node, assign the code to that symbol
        codes(nodes{1}.symbol) = code;
    else
        % Find the splitting point to balance the probabilities
        total_prob = sum(cellfun(@(x) x.probability, nodes));
        cumulative_prob = 0;
        split_idx = 0;
        
        for i = 1:numel(nodes)
            cumulative_prob = cumulative_prob + nodes{i}.probability;
            if cumulative_prob >= total_prob / 2
                split_idx = i;
                break;
            end
        end

        % Split into two groups
        left_nodes = nodes(1:split_idx);
        right_nodes = nodes(split_idx+1:end);

        % Recursively assign '0' to the left group and '1' to the right group
        generate_codes(left_nodes, [code '0'], codes);
        generate_codes(right_nodes, [code '1'], codes);
    end
end

% Generate Shannon-Fano codes
codes = shannon_fano_codes(nodes);

% Compress the data using the generated Shannon-Fano codes
compressed_data = arrayfun(@(x) codes(x), data, 'UniformOutput', false);

% Sort symbols and probabilities from most probable to least probable
[sorted_probabilities, sorted_indices] = sort(probabilities, 'descend');
sorted_symbols = symbols(sorted_indices);

% Display the Shannon-Fano codes for each symbol, sorted by probability
for i = 1:numel(sorted_symbols)
    fprintf('Symbol: %d, Probability: %.5f, Code: %s\n', sorted_symbols(i), sorted_probabilities(i), codes(sorted_symbols(i)));
end

% Entropy calculation
entropy = -sum(probabilities(probabilities > 0) .* log2(probabilities(probabilities > 0)));

% Average code length calculation
average_code_length = 0;
for i = 1:numel(symbols)
    code_length = length(codes(symbols(i)));
    average_code_length = average_code_length + probabilities(i) * code_length;
end

% Redundancy calculation
redundancy = average_code_length - entropy;

% Efficiency calculation
efficiency = (entropy/average_code_length)*100;

% Display results
fprintf('Entropy: %.5f bits\n', entropy);
fprintf('Efficiency: %.5f %%\n', efficiency);
fprintf('Average Code Length: %.5f bits\n', average_code_length);
fprintf('Redundancy: %.5f bits\n', redundancy);

% Save the compressed data as a cell array of binary strings
save('compressed_data.mat', 'compressed_data');

% Load the compressed data and the original symbols
load('compressed_data.mat'); % Load the compressed data
symbols = unique(data);       % Reuse the symbols from the original data
symbols = reshape(symbols, [], 1);  % Ensure it's a column vector

% Reverse lookup: Build a map of binary codes to symbols
reverse_codes = containers.Map('KeyType', 'char', 'ValueType', 'double');
for i = 1:numel(symbols)
    reverse_codes(codes(symbols(i))) = symbols(i);
end

% Decode the compressed data using the reverse lookup table
decoded_data = zeros(1, numel(compressed_data));  % Pre-allocate the array for speed
for i = 1:numel(compressed_data)
    decoded_data(i) = reverse_codes(compressed_data{i});  % Map the binary string back to its symbol
end

% Verify if the decoded data matches the original data
if isequal(decoded_data, data)
    disp('Decoding successful. The decoded data matches the original data.');
else
    disp('Decoding failed. The decoded data does not match the original data.');
end

% Optional: Plot the decoded signal to visually compare with the original signal
figure;
plot(time_axis, decoded_data);
xlabel('Time (seconds)');
ylabel('Voltage (mV)');
title('Decoded ECG Signal');
grid on;

% Create a bar graph of sorted symbols and their probabilities
figure;
bar(sorted_symbols, sorted_probabilities);
xlabel('Symbols');
ylabel('Probability');
title('Probability Distribution of Symbols');
grid on;

% Calculate the frequency of each symbol in the original and decoded data
original_freq = histcounts(data, bin_edges) / numel(data);
decoded_freq = histcounts(decoded_data, bin_edges) / numel(decoded_data);



