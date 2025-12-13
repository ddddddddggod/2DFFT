clear; clc; close all;

%% ===================== 기본 설정 =========================
WIDTH = 16;
N     = 128;
SCALE = 2^(WIDTH-1);
filename = 'robots.txt';

%% ===== Radar Parameter =====
fc  = 24e9;   
PRF = 1000;    
c   = 3e8;
lambda = c / fc;

%% ================= 1) Load File ==========================
fid = fopen(filename, 'r');
if fid == -1
    error('파일을 찾을 수 없습니다.');
end
data = fscanf(fid, '%x %x', [2, Inf]).';
fclose(fid);

% 데이터 개수 맞추기 (혹시 넘치면 자름)
if size(data, 1) > N*N
    data = data(1:N*N, :);
end

re = typecast(uint16(data(:,1)), 'int16');
im = typecast(uint16(data(:,2)), 'int16');
cplx = double(re)/SCALE + 1i*double(im)/SCALE;

%% ============ 2) 2D reshape & Pre-processing =============
X = reshape(cplx, [N, N]);   

% [★ 핵심 수정 1] 정지 클러터 제거 (Mean Subtraction)
% 각 Range Bin(행)마다 평균값을 뺍니다. 
% 이렇게 하면 벽이나 책상처럼 가만히 있는 물체(DC 성분)가 사라지고, 
% '변화하는' 신호(호흡, 움직임)만 남습니다.
%X = X - mean(X, 2); 

% Doppler shift
X = fftshift(X, 1);           

%% ============ 3) Magnitude & Noise Reduction =============
mag = abs(X);

% [★ 핵심 수정 2] 근거리 노이즈 마스킹 (Range Masking)
% 안테나 바로 앞(Range 0~2)은 Tx/Rx 누설 신호로 인해 노이즈가 심하므로 0으로 만듭니다.
%mag(1:3, :) = 0; 

% Log Scale
mag_db = 20*log10(mag + eps);

% [★ 핵심 수정 3] 노이즈 게이트 (Thresholding)
% 전체 신호 중 최대값 대비 -25dB 이하인 잡음들은 싹 다 바닥값으로 밀어버립니다.
% 이 숫자를 조절하세요 (-20: 깨끗함 / -30: 더 많이 보임)
NOISE_FLOOR_DB = -25; 
max_db = max(mag_db(:));
mag_db(mag_db < (max_db + NOISE_FLOOR_DB)) = max_db + NOISE_FLOOR_DB;

% Normalize 0~1
mag_norm = mag_db - min(mag_db(:));
mag_norm = mag_norm ./ max(mag_norm(:));

% Gaussian smoothing
mag_smooth = imgaussfilt(mag_norm, 1.0); % 스무딩 값을 1.2 -> 1.0으로 살짝 줄여 선명하게

% Final map
RD = mag_smooth.';

%% ============ 4) Velocity axis (m/s) ======================
vel_bins = (-N/2):(N/2-1);
v_axis = (lambda/2) * (vel_bins * (PRF/N));
range_bins = 0:N-1;

%% ============ 5) Visualization ===========================
figure('Color','w','Position',[200 200 900 600]);

% [★ 핵심 수정 4] 그래프 색상 범위 강제 조정 (CLim)
% 노이즈는 보통 0~0.4 구간에 깔려있습니다. 
% 하위 40%는 무시하고 상위 60% 신호만 색칠하도록 설정합니다.
imagesc(v_axis, range_bins, RD);
%set(gca, 'CLim', [0, 1.0]); 

set(gca,'YDir','normal');
xlabel('Velocity (m/s)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Range Bin', 'FontSize', 12, 'FontWeight', 'bold');
title('Breathing Range–Velocity Map', 'FontSize', 14);

% 컬러맵
cmap = [
    0.95 0.95 0.98;   % 배경 (아주 연한 회색) -> 노이즈 안 보이게 처리
    0.80 0.85 1.00;   
    0.60 0.65 0.95;   
    0.50 0.55 0.90;   
    0.45 0.40 0.75;   
    0.50 0.30 0.55;   
    0.85 0.55 0.65;   
    0.95 0.45 0.50;   
    1.00 0.20 0.25    % 강한 신호 (빨강)
];
colormap(interp1(linspace(0,1,size(cmap,1)), cmap, linspace(0,1,256)));

c = colorbar;
c.Label.String = 'Signal Strength (Normalized)';
c.FontSize = 12;

set(gca,'FontSize',12,'LineWidth',1.2);
grid off;

% 0 속도 기준선
%hold on;
%xline(0, '--k', 'LineWidth', 1, 'Alpha', 0.3);
%hold off;
