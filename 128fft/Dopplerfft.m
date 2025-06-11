clc; clear;

%% 1. Doppler FFT 입력 로드 (Q1.15 hex)
fid = fopen('fft_dopplerinput.txt', 'r');
if fid == -1
    error('fft_dopplerinput.txt 열기 실패');
end
hex_data = textscan(fid, '%4x %4x');  % 각 줄: real imag
fclose(fid);

% 2. 2''s complement 해석 (Q1.15 → int16)
re = double(hex_data{1});
im = double(hex_data{2});
re(re >= 2^15) = re(re >= 2^15) - 2^16;
im(im >= 2^15) = im(im >= 2^15) - 2^16;

% 복소수 신호
x = re + 1i * im;

%% 3. Q1.15 → float로 변환
FXP_FRAC = 15;
x_float = double(x) / 2^FXP_FRAC;

%% 4. FFT 계산 및 정규화 (Verilog 동작 반영: 1/N × 1/8)
N = length(x_float);
BF_SCALING = 3;  % >>>1 x3 = /8
total_scale = N * 2^BF_SCALING;  % = 128 * 8 = 1024
y = fft(x_float);
y_norm = y / total_scale;

%% 5. Q1.15 Multiply 스타일 (truncate + saturate)
to_q15 = @(val) max(min(floor(val * 2^FXP_FRAC), 32767), -32768);
re_q15 = int16(to_q15(real(y_norm)));
im_q15 = int16(to_q15(imag(y_norm)));

% 복원된 고정소수점 결과 (float 복소수)
y_fixed = double(re_q15) / 2^FXP_FRAC + 1i * double(im_q15) / 2^FXP_FRAC;

%% 6. 시각화
figure('Name', 'Doppler FFT Output (Q1.15)');
subplot(2,1,1);
stem(0:N-1, real(y_fixed), 'filled');
title('Real Part of Doppler FFT Output(Matlab)');
xlabel('FFT Bin'); ylabel('Amplitude'); grid on;
ylim([-1.0, 1.0]);

subplot(2,1,2);
stem(0:N-1, imag(y_fixed), 'filled');
title('Imaginary Part of Doppler FFT Output(Matlab)');
xlabel('FFT Bin'); ylabel('Amplitude'); grid on;
