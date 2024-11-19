import numpy as np
import matplotlib.pyplot as plt
from scipy.io import wavfile
import os

def sample_audio(audio, sampling_factor):
    """Downsample the audio signal by a given factor."""
    return audio[::sampling_factor]

def quantize_audio(audio, num_bits):
    """Quantize the audio signal to a specified bit depth."""
    max_val = 2 ** (num_bits - 1) - 1
    min_val = -(2 ** (num_bits - 1))
    audio_normalized = audio / np.max(np.abs(audio))  # Normalize
    quantized_audio = np.round(audio_normalized * max_val).astype(np.int16)
    return np.clip(quantized_audio, min_val, max_val)

def dpcm_encode(audio):
    """DPCM Encoding: Generates prediction error (encoded signal)."""
    encoded = np.zeros_like(audio, dtype=np.int16)
    prediction = 0  # Start with a zero prediction

    for i in range(len(audio)):
        error = audio[i] - prediction  # Calculate the error
        encoded[i] = error  # Store the error
        prediction += error  # Update prediction

    return encoded

def dpcm_decode(encoded):
    """DPCM Decoding: Reconstructs the original signal from encoded data."""
    decoded = np.zeros_like(encoded, dtype=np.int16)
    prediction = 0  # Start with zero prediction

    for i in range(len(encoded)):
        prediction += encoded[i]  # Add the error to prediction
        decoded[i] = prediction  # Store the reconstructed sample

    return decoded

def calculate_sqnr(original, quantized):
    """Calculate Signal-to-Quantization Noise Ratio (SQNR) in dB."""
    signal_power = np.sum(original ** 2)
    noise_power = np.sum((original - quantized) ** 2)
    sqnr = 10 * np.log10(signal_power / noise_power)
    return sqnr

def calculate_mse(original, decoded):
    """Calculate Mean Squared Error (MSE)."""
    mse = np.mean((original - decoded) ** 2)
    return mse

# Load the audio file
audio_file = 'C:/Users/Admin/Downloads/sample.wav'
if not os.path.exists(audio_file):
    raise FileNotFoundError(f"The file {audio_file} does not exist. Please check the path.")

sample_rate, audio = wavfile.read(audio_file)

# Normalize audio if it's not in int16 format
if audio.dtype != np.int16:
    audio = (audio / np.max(np.abs(audio)) * 32767).astype(np.int16)

# Step 1: Sampling the audio
sampling_factor = 2
sampled_audio = sample_audio(audio, sampling_factor)

# Step 2: Quantizing the audio
bit_depth = 8
quantized_audio = quantize_audio(sampled_audio, bit_depth)

# Step 3: DPCM Encoding and Decoding
encoded_audio = dpcm_encode(quantized_audio)
decoded_audio = dpcm_decode(encoded_audio)

# Step 4: Calculate SQNR and MSE
sqnr = calculate_sqnr(sampled_audio, quantized_audio)
mse = calculate_mse(quantized_audio, decoded_audio)

# Save the decoded audio
wavfile.write('decoded_audio.wav', sample_rate // sampling_factor, decoded_audio.astype(np.int16))

# Display SQNR and MSE
print(f"Signal-to-Quantization Noise Ratio (SQNR): {sqnr:.2f} dB")
print(f"Mean Squared Error (MSE): {mse:.2f}")

# Plot original, sampled, quantized, encoded, and decoded signals
plt.figure(figsize=(10, 12))

plt.subplot(6, 1, 1)
plt.plot(audio, label='Original Audio')
plt.title('Original Audio Signal')
plt.legend(loc='center left', bbox_to_anchor=(1, 0.5))  # Legend on the right side

plt.subplot(6, 1, 2)
plt.plot(sampled_audio, label='Sampled Audio')
plt.title(f'Sampled Audio Signal (Factor: {sampling_factor})')
plt.legend(loc='center left', bbox_to_anchor=(1, 0.5))  # Legend on the right side

plt.subplot(6, 1, 3)
plt.plot(quantized_audio, label='Quantized Audio')
plt.title(f'Quantized Audio Signal (Bit Depth: {bit_depth}-bit)')
plt.legend(loc='center left', bbox_to_anchor=(1, 0.5))  # Legend on the right side

plt.subplot(6, 1, 4)
plt.plot(encoded_audio, label='Encoded Audio (DPCM)')
plt.title('Encoded Audio Signal (DPCM)')
plt.legend(loc='center left', bbox_to_anchor=(1, 0.5))  # Legend on the right side

plt.subplot(6, 1, 5)
plt.plot(decoded_audio, label='Decoded Audio (DPCM)')
plt.title('Decoded Audio Signal (DPCM)')
plt.legend(loc='center left', bbox_to_anchor=(1, 0.5))  # Legend on the right side

# Add SQNR and MSE as text in the final plot
plt.subplot(6, 1, 6)
plt.axis('off')  # Turn off the axes for this plot
plt.text(0.1, 0.6, f"SQNR: {sqnr:.2f} dB", fontsize=12, fontweight='normal')
plt.text(0.1, 0.2, f"MSE: {mse:.2f}", fontsize=12, fontweight='normal')
plt.title('Performance Metrics')

# Adjust the layout for spacing
plt.tight_layout(pad=3.0)  # Adds padding between subplots

plt.show()
