clear; clc; close all;

%% ===================== 기본 설정 =========================
WIDTH = 16;
N     = 128;
SCALE = 2^(WIDTH-1);
filename = 'output_fft2d_matlab_12_14.txt';

%% ================= 1) Load File ==========================
fid = fopen(filename, 'r');
if fid == -1
    error('파일을 찾을 수 없습니다.');
end

% FPGA 출력: RRRR IIII (HEX)
data = fscanf(fid, '%x %x', [2, Inf]).';
fclose(fid);

% 정확히 N*N개만 사용
data = data(1:min(size(data,1), N*N), :);

re = typecast(uint16(data(:,1)), 'int16');
im = typecast(uint16(data(:,2)), 'int16');
cplx = double(re)/SCALE + 1i*double(im)/SCALE;

fprintf('Loaded samples: %d\n', length(cplx));

%% ================= 2) 1D RAW 검증 (가장 중요) =================
figure('Color','w');
plot(abs(cplx));
title('RAW FFT Output Stream (1D)');
xlabel('Sample Index');
ylabel('Magnitude');
grid on;

% 여기서 이미 peak가 구조적으로 보여야 함
% → 이게 깨져 있으면 MATLAB 이전 단계(Verilog) 문제

%% ================= 3) 2D 재배열 후보 4종 =====================
% FPGA 출력 순서를 모를 때 반드시 이 단계 필요

X1 = reshape(cplx, N, N);          % column-major
X2 = reshape(cplx, N, N).';        % transpose
X3 = reshape(cplx, N, N, 'F');     % explicit Fortran
X4 = reshape(cplx, N, N, 'F').';   % Fortran + transpose

figure('Color','w','Position',[200 200 900 600]);
subplot(2,2,1); imagesc(abs(X1)); title('X1 = reshape');
subplot(2,2,2); imagesc(abs(X2)); title('X2 = reshape^T');
subplot(2,2,3); imagesc(abs(X3)); title('X3 = reshape(F)');
subplot(2,2,4); imagesc(abs(X4)); title('X4 = reshape(F)^T');
colormap turbo; colorbar;

% 👉 이 중 "구조가 가장 자연스러운 것" 하나만 선택해야 함
% (Range 방향으로 선명한 수직 패턴 + Doppler 방향으로 peak)

%% ================= 4) ★ 최종 선택 (여기만 바꿔서 확정) =================
% 대부분의 2D FFT HW에서는 이게 정답인 경우가 많음
X = X2;   % <-- 필요하면 X1~X4 중 하나로 변경

%% ================= 5) 축 정의 (명시적으로) ====================
% 가정:
%  - row : Range
%  - col : Doppler

% Doppler FFT 중심 이동
X = fftshift(X, 2);

%% ================= 6) 최소 전처리 (검증용) ====================
% 정지 클러터 제거 (Range bin 별)
X = X - mean(X, 2);

mag = abs(X);
mag_db = 20*log10(mag + eps);

%% ================= 7) 시각화 ===============================
figure('Color','w','Position',[200 200 900 600]);
imagesc(mag_db);
set(gca,'YDir','normal');
xlabel('Doppler Bin');
ylabel('Range Bin');
title('Range–Doppler Map (Verification)');
colormap turbo;
colorbar;
