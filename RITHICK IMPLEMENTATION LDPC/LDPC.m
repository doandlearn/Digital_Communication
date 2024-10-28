function message_encoder_GUI()
    % Create a main figure window
    f = uifigure('Name', 'Message Encoder with Parity Bit', 'Position', [100 100 400 300]);

    % Add a label and text field for message input
    lbl = uilabel(f, 'Text', 'Enter a 4-bit message (e.g., 1100):', 'Position', [20 240 200 20]);
    message_entry = uieditfield(f, 'text', 'Position', [220 240 100 20]);

    % Add encode button
    encode_btn = uibutton(f, 'push', 'Text', 'Encode', 'Position', [150 200 100 30]);
    encode_btn.ButtonPushedFcn = @(~, ~) on_encode(message_entry, f);

    % Add labels to display encoded, noisy, and decoded messages
    encoded_label = uilabel(f, 'Position', [20 150 360 20]);
    noisy_label = uilabel(f, 'Position', [20 120 360 20]);
    decoded_label = uilabel(f, 'Position', [20 90 360 20]);

    % Define nested functions for encoding, noise simulation, and visualization
    function parity_bit = calculate_parity_bit(data)
        % Calculate the parity bit
        parity_bit = mod(sum(data), 2);
    end

    function encoded_message = encode_message(message)
        % Encode message with a parity bit
        parity_bit = calculate_parity_bit(message);
        encoded_message = [message, parity_bit];
    end

    function noisy_message = simulate_noise(encoded_message)
        % Simulate noise by flipping one random bit
        flip_index = randi([1, 5]);
        encoded_message(flip_index) = ~encoded_message(flip_index);
        noisy_message = encoded_message;
    end

    function [decoded_message, has_error] = decode_message(received_message)
        % Decode message and check for errors
        message = received_message(1:4);
        received_parity_bit = received_message(5);
        calculated_parity_bit = calculate_parity_bit(message);
        
        has_error = (received_parity_bit ~= calculated_parity_bit);
        decoded_message = message;
    end

    function visualize_parity(encoded_message, noisy_message)
        % Visualize encoding and noise simulation using MATLAB plotting
        figure;
        
        % Plot encoded and noisy messages
        x = 1:5;
        plot(x, encoded_message, 'o-', 'DisplayName', 'Encoded Message');
        hold on;
        plot(x, noisy_message, 'x-', 'DisplayName', 'Noisy Message');
        
        % Highlight the flipped bit
        for i = 1:5
            if encoded_message(i) ~= noisy_message(i)
                text(x(i), noisy_message(i) + 0.2, 'Flipped', 'Color', 'red', 'FontSize', 12);
                plot(x(i), noisy_message(i), 'ro');
            end
        end
        
        % Set plot properties
        xticks(x);
        xticklabels({'Bit 1', 'Bit 2', 'Bit 3', 'Bit 4', 'Parity'});
        ylim([-0.5, 1.5]);
        title('Encoding and Noise Simulation');
        xlabel('Bits');
        ylabel('Value');
        legend;
        hold off;
    end

    function on_encode(message_entry, f)
        % Validate and process the entered message
        message = message_entry.Value;
        
        % Check if the message is valid
        if length(message) ~= 4 || ~all(ismember(message, '01'))
            uialert(f, 'Please enter exactly 4 bits (0s and 1s).', 'Input Error');
            return;
        end

        % Convert message to numeric array
        message = str2num(message(:))'; %#ok<ST2NM>

        % Encode the message
        encoded_message = encode_message(message);
        noisy_message = simulate_noise(encoded_message);

        % Decode and check for errors
        [decoded_message, has_error] = decode_message(noisy_message);

        % Update labels with results
        encoded_label.Text = ['Encoded Message: ', num2str(encoded_message)];
        noisy_label.Text = ['Noisy Message: ', num2str(noisy_message)];
        if has_error
            decoded_label.Text = ['Error detected! After decoding: ', num2str(message)];
        else
            decoded_label.Text = ['Decoded Message: ', num2str(decoded_message)];
        end

        % Visualize the parity encoding and noise
        visualize_parity(encoded_message, noisy_message);
    end
end