load('data.mat');

sampling_frequency = 360;
time_axis = (0:length(data)-1) / sampling_frequency;

% Plot the original ECG signal
figure;
subplot(2,1,1);
plot(time_axis, data);
xlabel('Time (seconds)');
ylabel('Voltage (mV)');
title('Original ECG Signal');
grid on;

% Unique symbols and their probabilities
symbols = unique(data);
symbols = reshape(symbols, [], 1); % Ensure symbols is a column vector
bin_edges = [symbols; max(symbols) + 1];

% Calculate probabilities based on the occurrence of each symbol
probabilities = histcounts(data, bin_edges) / numel(data);

% Create nodes for each symbol
nodes = cell(1, numel(symbols));
for i = 1:numel(symbols)
    nodes{i} = struct('symbol', symbols(i), 'probability', probabilities(i));
end

% Build the Huffman Tree
while numel(nodes) > 1
    % Sort the nodes by probability
    [~, sort_idx] = sort(cellfun(@(x) x.probability, nodes));

    % Extract two nodes with the smallest probabilities
    node1 = nodes{sort_idx(1)};
    node2 = nodes{sort_idx(2)};

    % Create a new combined node
    new_node = struct('symbol', [], 'probability', node1.probability + node2.probability, 'left', node1, 'right', node2);

    % Remove the two nodes and add the new node
    nodes = [nodes(sort_idx(3:end)), new_node];
end

% Generate Huffman codes using containers.Map to avoid issues with field names
function codes = huffman_codes(node)
    codes = containers.Map('KeyType', 'double', 'ValueType', 'char');
    traverse_tree(node, '', codes);
end

function traverse_tree(node, code, codes)
    % Traverse the Huffman tree recursively to assign binary codes
    if isempty(node.symbol)
        % If the node is internal, traverse left and right
        traverse_tree(node.left, [code '0'], codes);
        traverse_tree(node.right, [code '1'], codes);
    else
        % If the node is a leaf, assign the code to the symbol
        codes(node.symbol) = code;
    end
end

% Generate Huffman codes
codes = huffman_codes(nodes{1});

% Compress the data using the generated Huffman codes
compressed_data = arrayfun(@(x) codes(x), data, 'UniformOutput', false);

% Sort symbols and probabilities from most probable to least probable
[sorted_probabilities, sorted_indices] = sort(probabilities, 'descend');
sorted_symbols = symbols(sorted_indices);

% Display the Huffman codes for each symbol, sorted by probability
for i = 1:numel(sorted_symbols)
    fprintf('Symbol: %d,\t Probability: %.5f,\t Code: %s\n', sorted_symbols(i), sorted_probabilities(i), codes(sorted_symbols(i)));
end

% Entropy calculation
entropy = -sum(probabilities(probabilities > 0) .* log2(probabilities(probabilities > 0)));

% Average code length calculation
average_code_length = 0;
for i = 1:numel(symbols)
    code_length = length(codes(symbols(i)));
    average_code_length = average_code_length + (probabilities(i) * code_length);
end

% Variance calculation
variance = 0;
for i = 1:numel(symbols)
    code_length = length(codes(symbols(i)));
    variance = variance + (probabilities(i) * (code_length-average_code_length)^2);
end

% Redundancy calculation
redundancy = average_code_length - entropy;

% Efficiency calculation
efficiency = (entropy/average_code_length)*100;

% Display results
fprintf('Entropy: %.5f bits\n', entropy);
fprintf('Average Code Length: %.5f bits\n', average_code_length);
fprintf('Variance: %.5f \n', variance);
fprintf('Redundancy: %.5f bits\n', redundancy);
fprintf('Efficiency: %.5f %%\n', efficiency);

% Save the compressed data as a cell array of binary strings
save('compressed_data.mat', 'compressed_data');


% Decoding the compressed data
decode_map = containers.Map(values(codes), keys(codes));  % Invert the Huffman code map for decoding

% Convert compressed data into a single binary string
encoded_str = strjoin(compressed_data, '');

% Initialize variables for decoding
decoded_data = zeros(1, length(data));  % Preallocate array for decoded data
current_code = '';
decoded_idx = 1;

% Decode the binary string
for i = 1:length(encoded_str)
    current_code = [current_code, encoded_str(i)];  % Append the current bit
    if isKey(decode_map, current_code)
        decoded_symbol = decode_map(current_code);   % Get the corresponding symbol
        decoded_data(decoded_idx) = decoded_symbol;  % Store in the decoded array
        decoded_idx = decoded_idx + 1;
        current_code = '';  % Reset the current code to start decoding the next symbol
    end
end

% Verify that the decoded data matches the original data
if isequal(data, decoded_data)
    disp('Decoding successful. The decoded data matches the original data.');
else
    disp('Decoding failed. The decoded data does not match the original data.');
end

% Plot the decoded ECG signal
subplot(2,1,2);
plot(time_axis, decoded_data);  % Plot the decoded data
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

