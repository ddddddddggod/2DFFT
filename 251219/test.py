import os
import numpy as np
import scipy.ndimage
import time
import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap

# ============================================================
# 기본 설정
# ============================================================
WIDTH = 16
N = 128
FRAME_SAMPLES = N * N * 2      # real + imag
SCALE = 2**(WIDTH-1)

FIFO_PATH = "/tmp/radar_fifo"
NOISE_FLOOR_DB = -5.0

# ============================================================
# Colormap (MATLAB 스타일)
# ============================================================
colors = [
    [0.95, 0.95, 0.98],
    [0.80, 0.85, 1.00],
    [0.60, 0.65, 0.95],
    [0.50, 0.55, 0.90],
    [0.45, 0.40, 0.75],
    [0.50, 0.30, 0.55],
    [0.85, 0.55, 0.65],
    [0.95, 0.45, 0.50],
    [1.00, 0.20, 0.25]
]
cmap_custom = LinearSegmentedColormap.from_list(
    "breathing_enhanced", colors, N=256
)

# ============================================================
# FIFO 준비
# ============================================================
if not os.path.exists(FIFO_PATH):
    os.mkfifo(FIFO_PATH)

print(">> Python Live Viewer Started")
pipe = open(FIFO_PATH, "rb")



# ============================================================
# Plot 준비
# ============================================================
plt.ion()
fig, ax = plt.subplots(figsize=(9, 6))

# ============================================================
# ★ 핵심: 누적 버퍼 (프레임 정렬용)
# ============================================================
buffer = np.array([], dtype=np.int16)

try:
    while True:
        # ----------------------------------------------------
        # 1. FIFO에서 작은 단위로 읽기 (안전)
        # ----------------------------------------------------
        raw = pipe.read(4096)
        if len(raw) == 0:
            continue

        new_data = np.frombuffer(raw, dtype='>i2')
        buffer = np.concatenate((buffer, new_data))

        # ----------------------------------------------------
        # 2. 프레임 단위로만 처리
        # ----------------------------------------------------
        while len(buffer) >= FRAME_SAMPLES:
            frame = buffer[:FRAME_SAMPLES]
            buffer = buffer[FRAME_SAMPLES:]

            start_time = time.time()

            # ------------------------------------------------
            # 3. Bytes → Complex
            # ------------------------------------------------
            re = frame[0::2].astype(np.float32) / SCALE
            im = frame[1::2].astype(np.float32) / SCALE
            cplx = re + 1j * im

            # ------------------------------------------------
            # 4. Reshape (MATLAB과 동일: Column-major)
            # ------------------------------------------------
            X = cplx.reshape((N, N), order='F')

            # ------------------------------------------------
            # 5. 정지 클러터 제거 (Mean Subtraction)
            # ------------------------------------------------
            X = X - np.mean(X, axis=1, keepdims=True)

            # Doppler FFT shift
            X = np.fft.fftshift(X, axes=0)

            # ------------------------------------------------
            # 6. Magnitude + Noise 처리
            # ------------------------------------------------
            mag = np.abs(X)
            mag[0:3, :] = 0     # 근거리 마스킹

            mag_db = 20 * np.log10(mag + np.finfo(float).eps)

            max_db = np.max(mag_db)
            threshold = max_db + NOISE_FLOOR_DB
            mag_db[mag_db < threshold] = threshold

            mag_norm = mag_db - np.min(mag_db)
            if np.max(mag_norm) > 0:
                mag_norm /= np.max(mag_norm)

            mag_smooth = scipy.ndimage.gaussian_filter(
                mag_norm, sigma=1.0
            )

            RD = mag_smooth.T

            # ------------------------------------------------
            # 7. Plot
            # ------------------------------------------------
            ax.clear()
            ax.imshow(
                RD,
                aspect='auto',
                origin='lower',
                cmap=cmap_custom
            )

            ax.set_title(
                f'Breathing Range–Velocity Map '
                f'(Max: {max_db:.2f} dB)',
                fontsize=14, fontweight='bold'
            )
            ax.set_xlabel('Velocity Bin')
            ax.set_ylabel('Range Bin')

            plt.draw()
            plt.pause(0.001)

            elapsed = (time.time() - start_time) * 1000
            # print(f">> Frame processed: {elapsed:.2f} ms")

except KeyboardInterrupt:
    pipe.close()
    plt.close()
    print("Closed.")
