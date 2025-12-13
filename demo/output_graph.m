clear; clc; close all;

%% ================= 1. 기본 설정 =========================
WIDTH = 16;
N     = 128;
SCALE = 2^(WIDTH-1);
filename = 'output_fft2d.txt';

%% ===== Radar Parameter =====
fc  = 24e9;   
PRF = 1000;    
c   = 3e8;
lambda = c / fc;

%% ================= 2. Load File & Data Fix =================
fid = fopen(filename, 'r');
if fid == -1
    error('파일을 찾을 수 없습니다. 경로를 확인하세요.');
end

% Hex 데이터 읽기
data = fscanf(fid, '%x %x', [2, Inf]).';
fclose(fid);

% 데이터 개수 확인 및 자르기 (★ 핵심 수정 부분)
% Verilog 파이프라인 지연으로 인해 16384개보다 더 많은 데이터가 들어왔을 경우
% 앞에서부터 정확히 N*N개만 취합니다.
current_len = size(data, 1);
expected_len = N * N;

if current_len > expected_len
    fprintf('Warning: 데이터가 %d개로 예상(%d)보다 많습니다. 뒷부분을 자릅니다.\n', current_len, expected_len);
    data = data(1:expected_len, :);
elseif current_len < expected_len
    error('Error: 데이터가 부족합니다 (%d/%d). Verilog 시뮬레이션 시간을 확인하세요.', current_len, expected_len);
end

% 16-bit Signed Conversion & Complex Construction
re = typecast(uint16(data(:,1)), 'int16');
im = typecast(uint16(data(:,2)), 'int16');
cplx = double(re)/SCALE + 1i*double(im)/SCALE;

%% ============ 3. 2D reshape & Doppler shift ==============
% 1D 배열을 2D 매트릭스로 변환 [128, 128]
X = reshape(cplx, [N, N]);   
X = fftshift(X, 1);          % Doppler shift (속도 0을 중심으로 이동)

%% ============ 4. Magnitude & smoothing ===================
mag = abs(X);

% Log Scale (작은 노이즈 억제 및 다내믹 레인지 확보)
mag_db = 20*log10(mag + eps);

% Normalize 0~1 (컬러맵 매핑을 위해)
mag_norm = mag_db - min(mag_db(:));
mag_norm = mag_norm ./ max(mag_norm(:));

% Gaussian smoothing (이미지를 부드럽게 만들어 시인성 향상)
mag_smooth = imgaussfilt(mag_norm, 1.2);

% Final Map (보통 Range가 Y축, Doppler가 X축)
% 데이터 저장 순서에 따라 전치(Transpose)가 필요할 수 있음.
% 현재 설정: RD의 행=Range, 열=Velocity라고 가정
RD = mag_smooth; 

%% ============ 5. Velocity Axis & Plotting Setup ==========
vel_bins = (-N/2):(N/2-1);
v_axis = (lambda/2) * (vel_bins * (PRF/N));
range_bins = 0:N-1;

% Custom Colormap (Breathing Highlight 버전 사용)
% 부드러운 파란색 배경 -> 호흡 신호(빨강) 강조
cmap = [
    0.90 0.90 0.95;   % Noise floor (Very light blue)
    0.75 0.80 1.00;   
    0.60 0.65 0.95;   
    0.50 0.55 0.90;   
    0.45 0.40 0.75;   
    0.50 0.30 0.55;   
    0.85 0.55 0.65;   % Weak signal (Pink)
    0.95 0.45 0.50;   % Normal signal (Soft Red)
    1.00 0.20 0.25    % Strong signal (Bright Red)
];

%% ============ 6. Visualization ===========================
figure('Color','w','Position',[200 200 900 600]);

% imagesc(x축데이터, y축데이터, 2D행렬)
% RD 행렬이 (Range x Doppler)라면 Transpose없이 그리는 것이 맞습니다.
% 만약 그림이 90도 돌아가 있다면 RD.' 로 바꿔주세요.
imagesc(v_axis, range_bins, RD); 

set(gca, 'YDir', 'normal'); % Y축 방향 (0이 아래쪽)
xlabel('Velocity (m/s)', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Range Bin', 'FontSize', 14, 'FontWeight', 'bold');
title('Breathing-Enhanced Range–Doppler Map', 'FontSize', 16);

% 컬러맵 적용 및 설정
colormap(interp1(linspace(0,1,size(cmap,1)), cmap, linspace(0,1,256))); % 부드러운 그라데이션 적용
c = colorbar;
c.Label.String = 'Normalized Magnitude';
c.Label.FontSize = 12;

% 그리드 및 폰트 설정
set(gca, 'FontSize', 12, 'LineWidth', 1.2);
grid off;

% (선택사항) 0 속도 지점 표시선
hold on;
xline(0, '--k', 'LineWidth', 1, 'Alpha', 0.5);
hold off;
