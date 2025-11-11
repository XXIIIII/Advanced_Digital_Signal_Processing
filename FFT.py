import numpy as np

def main():
    # Define two N-point real signals
    f1 = np.array([1, 2, 3, 4])
    f2 = np.array([5, 6, 7, 8])
    
    # Combine signals into complex signal: f3 = f1 + j*f2
    f3 = f1 + 1j * f2
    
    # Compute DFT of the combined signal
    F3 = np.fft.fft(f3)
    
    N = len(F3)
    F1 = []
    F2 = []
    
    # Extract F1 and F2 from F3 using symmetry properties
    for i in range(N):
        if i == 0:
            # DC component: F1[0] = real(F3[0]), F2[0] = imag(F3[0])
            F1.append(F3[i].real)
            F2.append(F3[i].imag)
        else:
            # For k != 0: use conjugate symmetry properties
            F1.append((F3[i] + np.conjugate(F3[N - i])) / 2)
            F2.append((F3[i] - np.conjugate(F3[N - i])) / 2j)
    
    # Display results
    print("F1 (DFT of f1):")
    print(F1)
    print("\nF2 (DFT of f2):")
    print(F2)

if __name__ == "__main__":
    main()
