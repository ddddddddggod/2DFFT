%% ===================== 1D FFT Output Verification =====================
clear; clc; close all;

WIDTH = 16;
SCALE = 2^(WIDTH-1);
filename = 'output_fft2d.txt';

%% Load file
fid = fopen(filename, 'r');
if fid == -1
    error('파일을 찾을 수 없습니다.');
end

data = fscanf(fid, '%x %x', [2, Inf]).';
fclose(fid);

re = typecast(uint16(data(:,1)), 'int16');
im = typecast(uint16(data(:,2)), 'int16');
cplx = double(re)/SCALE + 1i*double(im)/SCALE;

fprintf('Loaded samples: %d\n', length(cplx));

%% 1D magnitude plot
figure;
plot(abs(cplx), 'LineWidth', 1.2);
grid on;
xlabel('Sample Index');
ylabel('Magnitude');
title('1D RAW FFT Output Stream');

%% Optional: real / imag check
figure;
subplot(2,1,1);
plot(real(cplx)); grid on; title('Real Part');

subplot(2,1,2);
plot(imag(cplx)); grid on; title('Imag Part');

