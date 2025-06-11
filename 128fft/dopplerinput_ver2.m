clc; clear;

% Parameters
N = 128;                  % Doppler FFT point (slow-time length)
doppler_freq = 5;         % Doppler frequency (bin index)
amplitude = 0.8;          % Signal amplitude
scale = 2^15;             % Q1.15 scale factor

% Generate slow-time sinusoid for fixed range bin
n = 0:N-1;
data_re = amplitude * sin(2*pi*doppler_freq * n / N);
data_im = zeros(1, N);    % Pure real signal

% Q1.15 conversion
q15_re = int16(round(data_re * (scale - 1)));
q15_im = int16(round(data_im * (scale - 1)));

% Save to file: one line = real imag (hex, 16bit 2's complement)
filename = 'fft_dopplerinput.txt';
fid = fopen(filename, 'w');
if fid == -1
    error('파일 열기 실패: %s', filename);
end

for i = 1:N
    fprintf(fid, '%04X %04X\n', typecast(q15_re(i), 'uint16'), typecast(q15_im(i), 'uint16'));
end

fclose(fid);
fprintf('Doppler FFT 검증용 입력 파일 "%s" 생성 완료!\n', filename);
