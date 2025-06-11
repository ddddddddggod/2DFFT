clc; clear;

%% 1. Verilog와 동일한 Q1.15 입력 파일 읽기 (실수 + 허수)
fid = fopen('if_input2.txt', 'r');
hex_data = textscan(fid, '%4x %4x');  % 각 줄에 실수 4자리, 허수 4자리
fclose(fid);

% 2. 2's complement 부호 복원
d_re = double(hex_data{1});
d_im = double(hex_data{2});
d_re(d_re >= 2^15) = d_re(d_re >= 2^15) - 2^16;
d_im(d_im >= 2^15) = d_im(d_im >= 2^15) - 2^16;

% 3. Q1.15 고정소수점 → 부동소수점 변환
x_re = d_re / 2^15;
x_im = d_im / 2^15;
x = x_re + 1i * x_im;

N = length(x);

% 4. MATLAB FFT 수행 (Verilog처럼 1/N scaling)
X = fft(x) / N;

% 5. Verilog 출력처럼 bit-reverse 순서로 정렬
X_br = bitrevorder(X);

% 6. 결과 시각화 (y축 스케일 및 레이블 수정)
figure;

subplot(2,1,1);
stem(0:N-1, real(X_br), 'filled');
title('Real Part of FFT Output (bit-reversed, MATLAB)');
xlabel('Index'); ylabel('Real'); grid on;
ylim([-1e-17, 3e-5]);   % Real y축 스케일

subplot(2,1,2);
stem(0:N-1, imag(X_br), 'filled');
title('Imaginary Part of FFT Output (bit-reversed, MATLAB)');
xlabel('Index'); ylabel('Imaginary'); grid on;






















