clc; clear;

%% 1. Verilog에 입력한 것과 동일한 데이터 불러오기
fid = fopen('if_input.txt', 'r');
hex_data = textscan(fid, '%4x');
fclose(fid);

% 2. 16진수를 부호 있는 정수로 변환
data = double(hex_data{1});
data(data >= 2^15) = data(data >= 2^15) - 2^16;

% 3. 복소수 배열로 결합
N = 64;
if mod(length(data), 2) ~= 0
    error('입력 데이터가 짝수 개가 아닙니다. real/imag 짝수 쌍이어야 합니다.');
end

re = data(1:2:end);  % real part
im = data(2:2:end);  % imag part
x = re + 1i * im;

if length(x) ~= N
    warning('⚠️ 입력된 complex 샘플 개수 (%d개)가 N (%d)와 다릅니다.', length(x), N);
end

% 4. FFT 수행 (정규화 포함)
y = fft(x) / N;

% 5. 결과 출력
disp('Real part of FFT result:');
disp(real(y));
disp('Imaginary part of FFT result:');
disp(imag(y));

% 6. 플롯 (스케일 고정)
x_axis = 0:N-1;
maxval = max(abs([real(y); imag(y)]));
ylim_range = max(1, ceil(maxval * 1.1));

figure;
subplot(2,1,1);
stem(x_axis, real(y), 'filled');
title('MATLAB FFT Real Part');
xlabel('Index'); ylabel('Amplitude'); grid on;
xlim([0 N-1]); ylim([-ylim_range ylim_range]);

subplot(2,1,2);
stem(x_axis, imag(y), 'filled');
title('MATLAB FFT Imaginary Part');
xlabel('Index'); ylabel('Amplitude'); grid on;
xlim([0 N-1]); ylim([-ylim_range ylim_range]);

