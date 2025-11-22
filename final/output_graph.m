clear; clc;

%% 설정
WIDTH = 16;
SCALE = 2^(WIDTH-1);      % Q1.15 → 실수 변환
filename = 'output_fft2d.txt';   % 원하는 파일 이름으로 변경하세요

%% 1) 파일 읽기
fid = fopen(filename, 'r');
if fid == -1
    error('Cannot open %s', filename);
end

data = fscanf(fid, '%x %x', [2, Inf]).';
fclose(fid);

num_samples = size(data, 1);
idx = 1:num_samples;

%% 2) hex → uint16 → int16 → Q1.15 실수
re_u16 = uint16(data(:,1));
im_u16 = uint16(data(:,2));

re_i16 = typecast(re_u16, 'int16');
im_i16 = typecast(im_u16, 'int16');

re = double(re_i16) / SCALE;
im = double(im_i16) / SCALE;

%% 3) 그래프 출력: Real Part
figure;
plot(idx, re, 'b-', 'LineWidth', 1);
grid on;
xlabel('Sample index');
ylabel('Real value (Q1.15)');
title(['Real Part of ', filename], 'Interpreter', 'none');

%% 4) 그래프 출력: Imag Part
figure;
plot(idx, im, 'r-', 'LineWidth', 1);
grid on;
xlabel('Sample index');
ylabel('Imag value (Q1.15)');
title(['Imag Part of ', filename], 'Interpreter', 'none');
