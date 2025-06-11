% === Verilog FFT 결과만 시각화 ===
clc; clear;

% 1. 출력 데이터 로드
fid = fopen('fft_doppleroutput.txt', 'r');
hex_out = textscan(fid, '%4x %4x');
fclose(fid);

re = double(hex_out{1});
im = double(hex_out{2});
re(re >= 2^15) = re(re >= 2^15) - 2^16;
im(im >= 2^15) = im(im >= 2^15) - 2^16;

% 2. 복소수 결합 및 정렬
N = 128;
FXP_FRAC = 15;   % Q1.15
BF_SCALING = 3;  % >>>1 3단계 = /8

% 전체 스케일링 (Multiply: >>15, Butterfly: >>1 x3)
total_scale = 2^(FXP_FRAC + BF_SCALING);  % = 2^18 = 262144

y_verilog = (re + 1i * im) / total_scale;

% 출력은 Bit-reverse 순서이므로 정렬
bitrev_idx = bitrevorder(0:N-1) + 1;
y_verilog = y_verilog(bitrev_idx);

% 3. 시각화
figure('Name','Verilog FFT 결과');
subplot(2,1,1);
stem(0:N-1, real(y_verilog), 'filled');
title('Real Part of Doppler FFT Output(Verilog)'); xlabel('Bin'); ylabel('Amplitude'); grid on;

subplot(2,1,2);
stem(0:N-1, imag(y_verilog), 'filled');
title('Imag Part of Doppler FFT Output(Verilog)'); xlabel('Bin'); ylabel('Amplitude'); grid on;







