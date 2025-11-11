"""
ADSP Homework 4: Structural Similarity Index Measure (SSIM) Implementation
"""

import matplotlib.pyplot as plt
import math
import numpy as np

def calculate_ssim(image_reference, image_compared, 
                   stability_constant_1=1/math.sqrt(255), 
                   stability_constant_2=1/math.sqrt(255)):
    
    # Verify images have the same dimensions
    if image_reference.shape != image_compared.shape:
        raise ValueError("Images must have the same dimensions")
    
    height, width = image_reference.shape
    total_pixels = height * width
    
    mean_reference = 0
    mean_compared = 0
    
    for row in range(height):
        for col in range(width):
            mean_reference += image_reference[row, col]
            mean_compared += image_compared[row, col]
    
    mean_reference = mean_reference / total_pixels
    mean_compared = mean_compared / total_pixels
    
    print(f"Mean of reference image: {mean_reference:.4f}")
    print(f"Mean of compared image: {mean_compared:.4f}")
    
    variance_reference = 0
    variance_compared = 0
    
    for row in range(height):
        for col in range(width):
            variance_reference += (image_reference[row, col] - mean_reference) ** 2
            variance_compared += (image_compared[row, col] - mean_compared) ** 2
    
    variance_reference = variance_reference / total_pixels
    variance_compared = variance_compared / total_pixels
    
    covariance_cross = 0
    
    for row in range(height):
        for col in range(width):
            deviation_ref = image_reference[row, col] - mean_reference
            deviation_comp = image_compared[row, col] - mean_compared
            covariance_cross += deviation_ref * deviation_comp
    
    covariance_cross = covariance_cross / total_pixels
    
    dynamic_range = 255
    
    # Stability constants 
    c1_scaled = (stability_constant_1 * dynamic_range) ** 2
    c2_scaled = (stability_constant_2 * dynamic_range) ** 2
    
    numerator_luminance = (2 * mean_reference * mean_compared) + c1_scaled
    denominator_luminance = (mean_reference ** 2 + mean_compared ** 2) + c1_scaled
    
    numerator_contrast_structure = (2 * covariance_cross) + c2_scaled
    denominator_contrast_structure = (variance_reference + variance_compared) + c2_scaled
    
    # Final SSIM computation
    ssim_value = (numerator_luminance * numerator_contrast_structure) / \
                 (denominator_luminance * denominator_contrast_structure)
    
    return ssim_value

def main():
    try:
        reference_image = plt.imread("/content/monkey1.jpg")
        compared_image = plt.imread("/content/monkey2.jpg")
        
        print(f"Reference image shape: {reference_image.shape}")
        print(f"Compared image shape: {compared_image.shape}")
       
    except FileNotFoundError as e:
        print(f"Error loading images: {e}")
        return
    
    
    ssim_score = calculate_ssim(reference_image, compared_image)
    
    print(f"SSIM Score: {ssim_score:.6f}")
    
if __name__ == "__main__":
    main()
