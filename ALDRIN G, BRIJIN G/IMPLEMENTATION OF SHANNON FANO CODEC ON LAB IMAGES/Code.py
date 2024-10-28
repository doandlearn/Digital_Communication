import re
import numpy as np
from PIL import Image
import pydicom
import collections
import os
import math
import matplotlib.pyplot as plt
import cv2

name = ''

# Function to create the Results folder if not already present
def create_results_folder(n):
    folder_name = f'Results{n}'
    if not os.path.exists(folder_name):
        os.makedirs(folder_name)
    return folder_name

# Function to calculate PSNR
def calculate_psnr(image1_path, image2_path):
    img1 = cv2.imread(image1_path)
    img2 = cv2.imread(image2_path)
    
    if img1 is None:
        raise ValueError(f"Error: Could not load image at {image1_path}")
    if img2 is None:
        raise ValueError(f"Error: Could not load image at {image2_path}")
    
    if img1.shape != img2.shape:
        raise ValueError("Input images must have the same dimensions.")
    
    img1 = img1.astype(np.float32)
    img2 = img2.astype(np.float32)
    
    mse = np.mean((img1 - img2) ** 2)
    
    if mse == 0:
        return float('inf')
    
    max_pixel = 255.0
    psnr = 20 * np.log10(max_pixel / np.sqrt(mse))
    
    return psnr

print("\nShannon Image Compression Program")
print("=================================================================")

num_times = int(input("\nEnter the number of times to run the process: "))

for i in range(1, num_times + 1):
    results_folder = create_results_folder(i)
    
    print("\n=================================================================")

    print(f"\nRunning process for image {i}")
    
    h = int(input("\nInput RGB(1)/DICOM(2): "))

    if h == 1:
        file = input("\nEnter the filename: ")
        name = file
        original_image = Image.open(file)
        original_image.save(os.path.join(results_folder, 'original.jpg'))  # Save the original image
        my_string = np.asarray(original_image, np.uint8)
        sudhi = my_string
        shape = my_string.shape
        print("\n\nEntered image data is:")
        message = str(my_string.tolist())
    elif h == 2:
        file = input("\nEnter the DICOM filename: ")
        dicom_image = pydicom.dcmread(file)
        pixel_array = dicom_image.pixel_array
        shape = pixel_array.shape
        my_string = pixel_array.astype(np.uint8)
        sudhi = my_string
        print("\n\nEntered DICOM image data is:")
        message = str(my_string.tolist())
    else:
        print("\n\nYou entered an invalid input")
        exit()

    with open(os.path.join(results_folder, 'rawdata.txt'), 'w') as file:
        file.write(message)

    c = {}

    # Function to calculate probabilities and initialize the list
    def create_list(message):
        list = dict(collections.Counter(message))
        total_count = sum(list.values())
        for key, value in list.items():
            probability = round(value / total_count, 4)
            print(key, ' :  Count: ', value, ' Probability: ', probability)
        list_sorted = sorted(list.items(), key=lambda k_v: (k_v[1], k_v[0]), reverse=True)
        final_list = []
        for key, value in list_sorted:
            final_list.append([key, value, ''])
        print("\n")
        print("Shannon Fano Process:")
        return final_list

    # Function to divide the list in two parts as evenly as possible
    def divide_list(list):
        total_sum = sum(i[1] for i in list)
        running_sum = 0
        min_diff = float('inf')
        split_index = -1
        
        # Find the index that minimizes the difference between two groups
        for i in range(len(list)):
            running_sum += list[i][1]
            diff = abs(running_sum - (total_sum - running_sum))
            if diff < min_diff:
                min_diff = diff
                split_index = i
        
        return list[:split_index+1], list[split_index+1:]

    # Function to recursively label the symbols
    def label_list(list):
        if len(list) == 1:
            return
        list1, list2 = divide_list(list)
        
        for i in list1:
            i[2] += '0'
            c[i[0]] = i[2]
        for i in list2:
            i[2] += '1'
            c[i[0]] = i[2]
        
        # Recursive labeling
        label_list(list1)
        label_list(list2)
        
        return c

    code = label_list(create_list(message))
    print("\nShannon's Encoded Code:")

    letter_binary = []
    for key, value in code.items():
        print(key, ' : ', value)
        letter_binary.append([key, value])

    symbol_stats = []
    with open(os.path.join(results_folder, 'symbolstats.txt'), 'w') as file:
        for key, value in code.items():
            probability = message.count(key) / len(message)
            file.write(f"Symbol: {key}, Probability: {probability:.6f}, Code: {value}\n")
            symbol_stats.append({'Symbol': key, 'Probability': probability, 'Code Length': len(value)})

    with open(os.path.join(results_folder, 'compressed.txt'), 'w') as output:
        for a in message:
            for key, value in code.items():
                if key in a:
                    output.write(value)

    with open(os.path.join(results_folder, 'compressed.txt'), 'r') as output:
        bitstring = output.read()

    uncompressed_string = ""
    code = ""
    for digit in bitstring:
        code += digit
        pos = 0
        for letter in letter_binary:
            if code == letter[1]:
                uncompressed_string += letter_binary[pos][0]
                code = ""
            pos += 1

    with open(os.path.join(results_folder, 'uncompressed.txt'), 'w') as file:
        file.write(uncompressed_string)

    if h == 1 or h == 2:
        temp = re.findall(r'\d+', uncompressed_string)
        res = list(map(int, temp))
        res = np.array(res)
        res = res.astype(np.uint8)
        res = np.reshape(res, shape)
        print("\n\nObserve the shapes and input and output arrays are matching or not")
        print("Input image dimensions:", shape)
        print("Output image dimensions:", res.shape)
        data = Image.fromarray(res)
        data.save(os.path.join(results_folder, 'uncompressed.jpg'))
        if np.array_equal(sudhi, res):
            print("Success\n")
        
    print("Symbol Statistics:")
    entropy = 0
    lavg = 0
    efficiency = 0

    symbols = []
    counts = []
    code_lengths = []

    for stat in symbol_stats:
        symbols.append(stat['Symbol'])
        counts.append(stat['Probability'] * len(message))
        code_lengths.append(stat['Code Length'])

        p = stat['Probability']
        l = stat['Code Length']
        entropy += (p * math.log2(1/p))
        lavg += (p * l)

    efficiency = entropy / lavg

    print(f"Entropy: {entropy:.4f}\nAverage CodeWordLength: {lavg:.4f}\nEfficiency: {efficiency*100:.2f}%\n")
    
    # Calculate PSNR
    try:
        psnr_value = calculate_psnr(name, os.path.join(results_folder, 'uncompressed.jpg'))
        print(f"PSNR: {psnr_value:.2f}dB\n")
        if(psnr_value > 40):
            psnr = "Excellent quality, nearly imperceptible differences"
        elif((psnr_value > 30) and (psnr_value <= 40)):
            psnr = "Good quality with slight visible differences"
        elif((psnr_value > 20) and (psnr_value <= 30)):
            psnr = "Noticeable degradation in quality"
        elif(psnr_value <= 20):
            psnr = "Poor quality with significant differences"
        elif(psnr_value == float('inf')):
            psnr = "Exact Same Images!"
        print(psnr)
        print('\n')
        
    except ValueError as e:
        print(e)
        
    fig, ax1 = plt.subplots()

    color = 'tab:blue'
    ax1.set_xlabel('Symbols')
    ax1.set_ylabel('Count', color=color)
    ax1.bar(symbols, counts, color=color, alpha=0.6)
    ax1.tick_params(axis='y', labelcolor=color)

    ax2 = ax1.twinx()
    color = 'tab:red'
    ax2.set_ylabel('Code Length', color=color)
    ax2.plot(symbols, code_lengths, color=color, marker='o')
    ax2.tick_params(axis='y', labelcolor=color)

    fig.tight_layout()
    plt.title('Symbol Count and Code Length')
    plt.savefig(os.path.join(results_folder, 'symbol_count_code_length.png'))

    # Plot pie chart for entropy and average code word length
    labels = ['Entropy', 'Average Code Length']
    sizes = [entropy, lavg]
    colors = ['gold', 'lightcoral']
    explode = (0.1, 0)

    fig1, ax1 = plt.subplots()
    ax1.pie(sizes, explode=explode, labels=labels, colors=colors, autopct='%1.1f%%',
            shadow=True, startangle=140)
    ax1.axis('equal')

    plt.title('Ratio of Entropy and Average Code Length')
    plt.savefig(os.path.join(results_folder, 'entropy_avg_code_length_ratio.png'))
    
    print(f"Results saved in folder: {results_folder}")
    
print("\nProcess completed!\n\n")
