% 파일 읽기
fid = fopen('fft_output.txt', 'r');
raw = textscan(fid, '%4x %4x');  % 16bit hex 값 두 개 읽기
fclose(fid);

% 실수와 허수로 분리
re = double(raw{1});
im = double(raw{2});

% 부호 보정 (16bit 2's complement → signed integer)
re(re >= 2^15) = re(re >= 2^15) - 2^16;
im(im >= 2^15) = im(im >= 2^15) - 2^16;

% 복소수 조합
y = re + 1i*im;

% 플롯
figure;
subplot(2,1,1);
stem(real(y), 'filled'); title('Real Part of FFT Output'); grid on;

subplot(2,1,2);
stem(imag(y), 'filled'); title('Imaginary Part of FFT Output'); grid on;

