fid = fopen('fft_output2.txt', 'r');
raw = textscan(fid, '%4x %4x');  % 한 줄에 hex 2개: [real imag]
fclose(fid);

% 실수부 / 허수부 추출 및 double 변환
re = double(raw{1});
im = double(raw{2});

% === 부호 보정: 2's complement (16bit signed) ===
re(re >= 2^15) = re(re >= 2^15) - 2^16;
im(im >= 2^15) = im(im >= 2^15) - 2^16;

% === Q1.15 → 부동소수점 변환 ===
re = re / 2^15;
im = im / 2^15;

% === 복소수 조합 ===
y = re + 1i * im;

% === 도식화 ===
figure;
subplot(2,1,1);  % Real 값을 위에
stem(0:length(y)-1, real(y), 'filled');
title('Real Part of Verilog FFT Output');
xlabel('Frequency Bin'); ylabel('Real'); grid on;
ylim([-1e-17, 1e-17]);   % Real y축 스케일

subplot(2,1,2);  % Imag 값을 아래에
stem(0:length(y)-1, imag(y), 'filled');
title('Imaginary Part of Verilog FFT Output');
xlabel('Frequency Bin'); ylabel('Imag'); grid on;
ylim([-0.5, 0.5]);        % Imaginary y축 스케일

