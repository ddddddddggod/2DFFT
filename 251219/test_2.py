import os
import numpy as np
import scipy.ndimage
import time
import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap

# ============================================================
# 1. 기본 설정 및 파라미터
# ============================================================
WIDTH = 16
N = 128
# Real(2bytes) + Imag(2bytes) = 4bytes per sample
FRAME_SAMPLES = N * N * 2  
SCALE = 2**(WIDTH-1)

FIFO_PATH = "/tmp/radar_fifo"
NOISE_FLOOR_DB = -12.0  # 값이 너무 작으면 신호가 튑니다. -10 ~ -20 사이 권장

# 엔디안 설정: Arty Z7(Zynq)은 보통 Little-endian('<i2')입니다. 
# 만약 화면이 노이즈로 가득차면 '>i2'로 변경하세요.
DTYPE = '<i2' 

# ============================================================
# 2. Colormap 설정 (MATLAB 스타일)
# ============================================================
colors = [
    [0.95, 0.95, 0.98], [0.80, 0.85, 1.00], [0.60, 0.65, 0.95],
    [0.50, 0.55, 0.90], [0.45, 0.40, 0.75], [0.50, 0.30, 0.55],
    [0.85, 0.55, 0.65], [0.95, 0.45, 0.50], [1.00, 0.20, 0.25]
]
cmap_custom = LinearSegmentedColormap.from_list("breathing_enhanced", colors, N=256)

# ============================================================
# 3. FIFO 및 Plot 초기화
# ============================================================
if not os.path.exists(FIFO_PATH):
    os.mkfifo(FIFO_PATH)

print(">> Python Live Viewer Started. Waiting for data...")
pipe = open(FIFO_PATH, "rb")

plt.ion()
fig, ax = plt.subplots(figsize=(10, 7))

# [성능 최적화] imshow 객체를 미리 생성하여 데이터만 갱신합니다.
im_plot = ax.imshow(
    np.zeros((N, N)), 
    aspect='auto', 
    origin='lower', 
    cmap=cmap_custom,
    vmin=0, vmax=1  # 정규화된 데이터(0~1)를 그립니다.
)

ax.set_title('Breathing Range-Velocity Map', fontsize=14, fontweight='bold')
ax.set_xlabel('Velocity Bin (Doppler)')
ax.set_ylabel('Range Bin')
fig.colorbar(im_plot, ax=ax, label='Normalized Intensity')

# 윈도우 함수 미리 계산 (Range 축 흔들림 방지용)
window = np.hamming(N).reshape(-1, 1)

# 누적 버퍼
buffer = np.array([], dtype=np.int16)

# ============================================================
# 4. 메인 처리 루프
# ============================================================
try:
    while True:
        # FIFO에서 데이터 읽기 (작은 단위로 읽어 버퍼에 누적)
        raw = pipe.read(8192)
        if len(raw) == 0:
            continue

        new_data = np.frombuffer(raw, dtype=DTYPE)
        buffer = np.concatenate((buffer, new_data))

        # 프레임 단위(N*N*2 samples)가 쌓였을 때만 처리
        while len(buffer) >= FRAME_SAMPLES:
            frame = buffer[:FRAME_SAMPLES]
            buffer = buffer[FRAME_SAMPLES:]

            start_processing = time.time()

            # (1) 데이터 복소수 변환
            re = frame[0::2].astype(np.float32) / SCALE
            im = frame[1::2].astype(np.float32) / SCALE
            cplx = re + 1j * im

            # (2) Reshape
            X = cplx.reshape((N, N), order='F')

            # (3) [중요] 윈도우 적용 - Range 축의 에너지가 옆으로 새는 것을 방지
            X = X * window

            # (4) FFT Shift - 0Hz(정지 상태)를 중앙으로 이동
            X_shifted = np.fft.fftshift(X, axes=0)

            # (5) [핵심] 특정 Bin(DC)만 제거 - 1Hz 신호를 살리기 위해 0번 속도만 지움
            # syntax error 방지를 위해 명확한 인덱싱 사용
            mid = N // 2
            X_shifted[mid, :] = 0 

            # (6) Magnitude 및 Log Scale 변환
            mag = np.abs(X_shifted)
            mag[0:4, :] = 0  # 안테나 직전 근거리 잡음 마스킹
            
            mag_db = 20 * np.log10(mag + 1e-10) # 0 에러 방지용 아주 작은 값 더하기

            # (7) 노이즈 게이트 적용
            max_val = np.max(mag_db)
            thresh = max_val + NOISE_FLOOR_DB
            mag_db[mag_db < thresh] = thresh

            # (8) 시각화를 위한 정규화 (0 ~ 1)
            mag_norm = mag_db - np.min(mag_db)
            if np.max(mag_norm) > 0:
                mag_norm /= np.max(mag_norm)

            # (9) 가우시안 스무딩 (부드러운 화면)
            RD = scipy.ndimage.gaussian_filter(mag_norm.T, sigma=0.8)

            # (10) [성능 최적화] 그래프 업데이트
            im_plot.set_data(RD)
            ax.set_title(f'Range-Velocity Map (Max: {max_val:.1f} dB)')
            
            fig.canvas.draw_idle()
            plt.pause(0.001) # 짧은 일시정지로 화면 갱신 보장

except KeyboardInterrupt:
    print("\n>> Stopping Viewer...")
finally:
    pipe.close()
    plt.close()
    print(">> Closed.")
