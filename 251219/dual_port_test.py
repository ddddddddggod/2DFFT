import spidev
import numpy as np
import scipy.ndimage
import time
import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap

# === 1. 설정 및 초기화 ===
N = 128
TOTAL_POINTS = N * N  # 16,384
SPI_SPEED = 10000000  # 10MHz (FPGA sys_clk와 안정성 고려하여 조절)
NOISE_FLOOR_DB = -5.0

# SPI 설정
spi = spidev.SpiDev()
spi.open(0, 0) # CE0 (ck_ss) 연결
spi.max_speed_hz = SPI_SPEED
spi.mode = 0

# 시각화 설정 (MATLAB 스타일 색상표 유지)
colors = [
    [0.95, 0.95, 0.98], [0.80, 0.85, 1.00], [0.60, 0.65, 0.95], 
    [0.50, 0.55, 0.90], [0.45, 0.40, 0.75], [0.50, 0.30, 0.55], 
    [0.85, 0.55, 0.65], [0.95, 0.45, 0.50], [1.00, 0.20, 0.25]
]
cmap_custom = LinearSegmentedColormap.from_list("breathing_enhanced", colors, N=256)

def signed_16(val):
    """16비트 unsigned 데이터를 signed로 변환"""
    return val if val < 32768 else val - 65536

def fetch_fpga_data():
    """SPI를 통해 FPGA BRAM에서 128x128 데이터를 읽어옴"""
    frame_cplx = np.zeros(TOTAL_POINTS, dtype=complex)
    
    for i in range(TOTAL_POINTS):
        # 1. 14비트 주소를 2바이트로 분할하여 전송 준비 (상위 14비트 사용)
        addr_h = (i >> 8) & 0xFF
        addr_l = i & 0xFF
        
        # 2. SPI 통신: [주소H, 주소L] 보내고 [D3, D2, D1, D0] 받기 (총 6바이트)
        # FPGA SPI Slave 설계상 주소 수신 후 바로 데이터를 내보내므로 6바이트 전송
        resp = spi.xfer2([addr_h, addr_l, 0, 0, 0, 0])
        
        # 3. 데이터 복원 (상위 16비트: Real, 하위 16비트: Imag)
        # resp[0,1]은 주소 전송용, resp[2,3,4,5]가 데이터
        raw_real = (resp[2] << 8) | resp[3]
        raw_imag = (resp[4] << 8) | resp[5]
        
        re = signed_16(raw_real)
        im = signed_16(raw_imag)
        frame_cplx[i] = re + 1j * im
        
    return frame_cplx

# === 2. 메인 루프 및 시각화 ===
plt.ion()
fig, ax = plt.subplots(figsize=(10, 7))

print(">> FPGA SPI Live Viewer Started. Reading 128x128 Range-Doppler Map...")

try:
    while True:
        start_time = time.time()
        
        # 1. FPGA로부터 데이터 수집
        cplx_data = fetch_fpga_data()
        
        # 2. 데이터 전처리
        # FPGA에서 순차적으로 저장했으므로 Reshape (128x128)
        X = cplx_data.reshape((N, N)) 
        
        # [정지 클러터 제거] Mean Subtraction
        X = X - np.mean(X, axis=1, keepdims=True)
        
        # [Doppler Shift] 센터 정렬
        X = np.fft.fftshift(X, axes=0)
        
        # 3. Magnitude 및 Log Scale 계산
        mag = np.abs(X)
        mag[0:3, :] = 0  # 근거리 노이즈 마스킹
        
        mag_db = 20 * np.log10(mag + 1e-9)
        
        # 4. 노이즈 게이트 및 정규화
        max_db = np.max(mag_db)
        threshold = max_db + NOISE_FLOOR_DB
        mag_db[mag_db < threshold] = threshold
        
        mag_norm = mag_db - np.min(mag_db)
        if np.max(mag_norm) != 0:
            mag_norm = mag_norm / np.max(mag_norm)
            
        # 가우시안 스무딩
        mag_smooth = scipy.ndimage.gaussian_filter(mag_norm, sigma=1.0)
        
        # 5. 그래프 업데이트
        ax.clear()
        # Range-Velocity Map (Transpose하여 출력 방향 조정)
        im = ax.imshow(mag_smooth.T, aspect='auto', origin='lower', cmap=cmap_custom)
        
        ax.set_title(f'Range-Doppler Map (Max: {max_db:.2f} dB)', fontsize=12)
        ax.set_xlabel('Doppler Bin (Velocity)', fontsize=10)
        ax.set_ylabel('Range Bin', fontsize=10)
        
        plt.draw()
        plt.pause(0.1) # 갱신 속도 조절
        
        print(f">> Frame updated | Read Time: {time.time() - start_time:.2f}s")

except KeyboardInterrupt:
    spi.close()
    plt.close()
    print("Stopped by User.")
