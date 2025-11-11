"""
ADSP Homework 3: Image Compression
"""

import matplotlib.pyplot as plt
import numpy as np

# Load and display original image
image = plt.imread("/content/wallpaper 1.jpg").astype(np.float32) 

print("Original Image:")
plt.imshow(image / 255)
plt.show()

# Apply YCbCr transformation matrix
Y_channel = 0.299 * image[:, :, 0] + 0.587 * image[:, :, 1] + 0.114 * image[:, :, 2]
Cb_channel = -0.169 * image[:, :, 0] - 0.331 * image[:, :, 1] + 0.5 * image[:, :, 2]
Cr_channel = 0.5 * image[:, :, 0] - 0.419 * image[:, :, 1] - 0.081 * image[:, :, 2]

# Stack channels to create YCbCr image
ycbcr_image = np.stack((Y_channel, Cb_channel, Cr_channel), axis=2)
print(f"YCbCr image shape: {ycbcr_image.shape}")

# Downsample Cb and Cr channels by factor of 2 (keep every other pixel)
compressed_Cb = Cb_channel[::2, ::2]
compressed_Cr = Cr_channel[::2, ::2]

print(f"Compressed Cb shape: {compressed_Cb.shape}")
print(f"Compressed Cr shape: {compressed_Cr.shape}")

height, width = image.shape[:2]

# Initialize upsampled chroma channels
upsampled_Cb = np.zeros((height, width), dtype='float32')
upsampled_Cr = np.zeros((height, width), dtype='float32')

# Place compressed samples back at their original positions
upsampled_Cb[::2, ::2] = compressed_Cb
upsampled_Cr[::2, ::2] = compressed_Cr

def interpolate_horizontally(channel, height, width):
    for i in range(0, height, 2):
        for j in range(1, width, 2):
            if j == width - 1:
                # Handle boundary case
                channel[i][j] = channel[i][j-1] / 2
            else:
                # Linear interpolation between neighboring pixels
                channel[i][j] = (channel[i][j-1] + channel[i][j+1]) / 2

def interpolate_vertically(channel, height, width):
    for j in range(0, width, 1):
        for i in range(1, height, 2):
            if i == height - 1:
                # Handle boundary case
                channel[i][j] = channel[i-1][j] / 2
            else:
                # Linear interpolation between neighboring pixels
                channel[i][j] = (channel[i-1][j] + channel[i+1][j]) / 2

# Apply interpolation to both chroma channels
interpolate_horizontally(upsampled_Cb, height, width)
interpolate_vertically(upsampled_Cb, height, width)
interpolate_horizontally(upsampled_Cr, height, width)
interpolate_vertically(upsampled_Cr, height, width)

# Reconstruct interpolated YCbCr image
interpolated_ycbcr = np.stack((Y_channel, upsampled_Cb, upsampled_Cr), axis=2)

# Define YCbCr to RGB transformation matrix
ycbcr_to_rgb_matrix = np.array([
    [0.299, 0.587, 0.114],
    [-0.169, -0.331, 0.5],
    [0.5, -0.419, -0.081]
])

inverse_transform_matrix = np.linalg.inv(ycbcr_to_rgb_matrix)

# Apply inverse transformation to each channel
R_channel = (inverse_transform_matrix[0, 0] * interpolated_ycbcr[:, :, 0] + 
             inverse_transform_matrix[0, 1] * interpolated_ycbcr[:, :, 1] + 
             inverse_transform_matrix[0, 2] * interpolated_ycbcr[:, :, 2])

G_channel = (inverse_transform_matrix[1, 0] * interpolated_ycbcr[:, :, 0] + 
             inverse_transform_matrix[1, 1] * interpolated_ycbcr[:, :, 1] + 
             inverse_transform_matrix[1, 2] * interpolated_ycbcr[:, :, 2])

B_channel = (inverse_transform_matrix[2, 0] * interpolated_ycbcr[:, :, 0] + 
             inverse_transform_matrix[2, 1] * interpolated_ycbcr[:, :, 1] + 
             inverse_transform_matrix[2, 2] * interpolated_ycbcr[:, :, 2])

# Reconstruct RGB image
reconstructed_rgb = np.stack((R_channel, G_channel, B_channel), axis=2)
reconstructed_rgb = reconstructed_rgb.astype(np.float32)

print("Displaying reconstructed image...")
plt.figure(figsize=(12, 6))

plt.subplot(1, 2, 1)
plt.title("Original Image")
plt.imshow(image / 255)
plt.axis('off')

plt.subplot(1, 2, 2)
plt.title("Reconstructed Image (After Compression)")
plt.imshow(reconstructed_rgb / 255)
plt.axis('off')

plt.tight_layout()
plt.show()

print("Image compression and reconstruction completed!")
