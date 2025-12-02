clear; clc;

%% ===================== 기본 설정 =========================
WIDTH = 16;
N     = 128;
SCALE = 2^(WIDTH-1);

filename = 'output_fft2d_matlab.txt';

%% ===== Radar Parameter =====
fc  = 24e9;   
PRF = 1000;    
c   = 3e8;
lambda = c / fc;

%% ================= 1) Load File ==========================
fid = fopen(filename, 'r');
data = fscanf(fid, '%x %x', [2, Inf]).';
fclose(fid);

re = typecast(uint16(data(:,1)), 'int16');
im = typecast(uint16(data(:,2)), 'int16');
cplx = double(re)/SCALE + 1i*double(im)/SCALE;

%% ============ 2) 2D reshape & Doppler shift ==============
X = reshape(cplx, [N, N]);   
X = fftshift(X,1);           % Doppler shift

%% ============ 3) Magnitude & smoothing ===================
mag = abs(X);

% log scale → 눈에 거슬리는 작은 노이즈 제거
mag_db = 20*log10(mag + eps);

% Normalize 0~1
mag_norm = mag_db - min(mag_db(:));
mag_norm = mag_norm ./ max(mag_norm(:));

% Gaussian smoothing (사람 움직임 표현이 더 자연스러움)
mag_smooth = imgaussfilt(mag_norm, 1.2);

% final map (Range x Vel)
RD = mag_smooth.';

%% ============ 4) Velocity axis (m/s) ======================
vel_bins = (-N/2):(N/2-1);
v_axis = (lambda/2) * (vel_bins * (PRF/N));

%% ============ 5) Custom colormap (눈 편한 버전) ============
% Blue → Black → Red (noise = dark, person = red)
cmap = [
    0   0   0.4;   % deep blue
    0   0   0.0;   % black
    0.4 0   0;     % dark red
    0.8 0   0;     % red
    1.0 0.3 0.3    % bright red
];

%% ============ 6) Plot ====================================
figure('Color','w','Position',[200 200 900 600]);

imagesc(v_axis, 0:N-1, RD);
set(gca,'YDir','normal');

xlabel('Velocity (m/s)', 'FontSize', 12);
ylabel('Range Bin', 'FontSize', 12);
title('Breathing-Enhanced Range–Velocity Map', 'FontSize', 14);

% ---------------------------------------------------------
cmap = [
    0.90 0.90 0.95;   % very light grayish blue (noise floor)
    0.75 0.80 1.00;   % soft blue
    0.60 0.65 0.95;   % gentle periwinkle
    0.50 0.55 0.90;   % medium blue-purple
    0.45 0.40 0.75;   % muted violet
    0.50 0.30 0.55;   % muted purple
    0.85 0.55 0.65;   % pastel pink (weak breathing)
    0.95 0.45 0.50;   % soft red (normal breathing)
    1.00 0.20 0.25    % highlight red (strong breathing)
];

colormap(cmap);

c = colorbar;
c.Label.String = 'Normalized magnitude (Breathing Highlight)';
c.FontSize = 12;

set(gca,'FontSize',12,'LineWidth',1.0);
grid off;
