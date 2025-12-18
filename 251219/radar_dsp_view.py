import os
import numpy as np
import scipy.ndimage
import time
import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap

# === 설정 ===
WIDTH = 16
N = 128
FIFO_PATH = "/tmp/radar_fifo"
SCALE = 2**(WIDTH-1)
NOISE_FLOOR_DB = -5.0  # [핵심 3] 노이즈 게이트 임계값 (-25dB)

# === 시각화 설정 (MATLAB 코드 기반 색상표) ===
# 배경(연회색) -> 파랑 -> 보라 -> 빨강 (강한 신호)
colors = [
    [0.95, 0.95, 0.98], # 배경 (아주 연한 회색)
    [0.80, 0.85, 1.00], 
    [0.60, 0.65, 0.95], 
    [0.50, 0.55, 0.90], 
    [0.45, 0.40, 0.75], 
    [0.50, 0.30, 0.55], 
    [0.85, 0.55, 0.65], 
    [0.95, 0.45, 0.50], 
    [1.00, 0.20, 0.25]  # 강한 신호 (빨강)
]
# MATLAB의 interp1처럼 부드럽게 그라데이션 생성
cmap_custom = LinearSegmentedColormap.from_list("breathing_enhanced", colors, N=256)

# 파이프 생성
if not os.path.exists(FIFO_PATH):
    os.mkfifo(FIFO_PATH)

print(">> Python Live Viewer Started. Waiting for data...")
pipe = open(FIFO_PATH, "rb")

# 대화형 모드 켜기
plt.ion()
fig, ax = plt.subplots(figsize=(9, 6))

try:
    while True:
        # 1. 데이터 읽기 (64KB)
        raw_data = pipe.read(65536)
        if len(raw_data) < 65536:
            continue
            
        start_time = time.time()
        
        # 2. 데이터 전처리 (Bytes -> Complex)
        int_data = np.frombuffer(raw_data, dtype='>i2')
        if len(int_data) < N*N*2:
            padding = np.zeros((N*N*2) - len(int_data), dtype='<i2')
            int_data = np.concatenate((int_data, padding))
            
        re = int_data[0::2]
        im = int_data[1::2]
        cplx = (re.astype(np.float32) / SCALE) + 1j * (im.astype(np.float32) / SCALE)
        
        # 3. Reshape (MATLAB과 동일하게 Column-major 순서)
        X = cplx.reshape((N, N), order='F') 
        
        # [★ 핵심 수정 1] 정지 클러터 제거 (Mean Subtraction)
        # 각 Range Bin(행)마다 평균값을 뺍니다.
        # Python axis=1은 열(Column) 방향 평균이므로 MATLAB mean(X, 2)와 동일
        X = X - np.mean(X, axis=1, keepdims=True)
        
        # Doppler Shift (Row 방향 Shift)
        X = np.fft.fftshift(X, axes=0)
        
        # 4. Magnitude 계산
        mag = np.abs(X)
        
        # [★ 핵심 수정 2] 근거리 노이즈 마스킹 (Range Masking)
        # 안테나 바로 앞 (Range Index 0~2) 제거
        mag[0:3, :] = 0
        
        # Log Scale
        mag_db = 20 * np.log10(mag + np.finfo(float).eps)
        
        # [★ 핵심 수정 3] 노이즈 게이트 (Thresholding)
        # 최대값 대비 -25dB 이하인 잡음들은 바닥값으로 밀어버림
        max_db = np.max(mag_db)
        threshold = max_db + NOISE_FLOOR_DB
        mag_db[mag_db < threshold] = threshold
        
        # Normalize (0~1)
        mag_norm = mag_db - np.min(mag_db)
        if np.max(mag_norm) != 0:
            mag_norm = mag_norm / np.max(mag_norm)
            
        # Gaussian Smoothing (Sigma 1.0으로 조정)
        mag_smooth = scipy.ndimage.gaussian_filter(mag_norm, sigma=1.0)
        
        # Final Transpose (Range-Velocity Map)
        RD = mag_smooth.T
        
        # 5. 화면 그리기
        ax.clear()
        
        # Velocity 축과 Range 축 설정 (MATLAB 코드 기준)
        # 이미지는 배열 인덱스로 표현되지만, aspect='auto'로 비율 유지
        im = ax.imshow(RD, aspect='auto', origin='lower', cmap=cmap_custom)
        
        # [★ 핵심 수정 4] 시각화 옵션 적용
        # clim(0, 1.0)과 유사하게 데이터가 이미 Normalize 됨
        
        ax.set_title(f'Breathing Range-Velocity Map (Max: {max_db:.2f} dB)', fontsize=14, fontweight='bold')
        ax.set_xlabel('Velocity (m/s)', fontsize=12, fontweight='bold')
        ax.set_ylabel('Range Bin', fontsize=12, fontweight='bold')
        
        # 화면 업데이트
        plt.draw()
        plt.pause(0.5)
        
        elapsed = (time.time() - start_time) * 1000
        # print(f">> Processed | Time: {elapsed:.2f} ms") 

except KeyboardInterrupt:
    pipe.close()
    plt.close()
    print("Closed.")
