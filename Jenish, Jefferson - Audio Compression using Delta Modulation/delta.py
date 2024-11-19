import numpy as np
import matplotlib.pyplot as plt
import soundfile as sf

def delta_modulation(input_signal, delta):
    compressed_signal = np.zeros(len(input_signal))
    predicted_signal = np.zeros(len(input_signal))
    
    for i in range(1, len(input_signal)):
        if input_signal[i] > predicted_signal[i-1]:
            compressed_signal[i] = 1
            predicted_signal[i] = predicted_signal[i-1] + delta
        else:
            compressed_signal[i] = -1
            predicted_signal[i] = predicted_signal[i-1] - delta
    
    return compressed_signal, predicted_signal

def delta_demodulation(compressed_signal, delta):
    decompressed_signal = np.zeros(len(compressed_signal))
    
    for i in range(1, len(compressed_signal)):
        decompressed_signal[i] = decompressed_signal[i-1] + compressed_signal[i] * delta
    
    return decompressed_signal

# Load an audio file (e.g., a .wav file)
input_signal, sample_rate = sf.read('input.wav')

# Normalize the input signal
input_signal = input_signal / np.max(np.abs(input_signal))

# Set delta (step size for delta modulation)
delta = 0.01

# Delta Modulation (Compression)
compressed_signal, predicted_signal = delta_modulation(input_signal, delta)

# Delta Demodulation (Decompression)
decompressed_signal = delta_demodulation(compressed_signal, delta)

# Save the decompressed signal as an output audio file
sf.write('output_audio.wav', decompressed_signal, sample_rate)

# Plot the original, compressed, and decompressed signals
plt.figure(figsize=(15,5))

plt.subplot(3,1,1)
plt.plot(input_signal)
plt.title('Original Signal')

plt.subplot(3,1,2)
plt.plot(compressed_signal)
plt.title('Compressed Signal (Delta Modulation)')

plt.subplot(3,1,3)
plt.plot(decompressed_signal)
plt.title('Decompressed Signal')

plt.tight_layout()
plt.show()
