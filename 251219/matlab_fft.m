%======================================================================
% 2D FFT (128x128) - Verilog FFT2D_128x128 구조를 최대한 반영한 MATLAB 모델
% - 입력 : input_complex.txt (각 줄: "real imag" 16bit hex, Q1.15 fixed-point)
% - 처리 :
%     1) Range 방향 128pt FFT (행 기준, fast-time 방향)
%        - FFT → /128 정규화
%        - bit-reversed 출력 인덱스 적용
%     2) 전치 버퍼 효과 (row-major write, column-major read와 동치 구조)
%     3) Doppler 방향 128pt FFT (열 기준, slow-time 방향)
%        - FFT → /128 정규화
%        - bit-reversed 출력 인덱스 적용
%     4) 최종 결과를 Q1.15로 양자화 후 hex로 출력
%
% - 출력 : output_fft2d_matlab.txt
%          (각 줄: "real imag" 16bit hex, Verilog output_fft2d.txt와 비교용)
%======================================================================

clear; clc;

%% 파라미터
WIDTH = 16;
N     = 128;
SCALE = 2^(WIDTH-1);   % Q1.15 => 2^15

in_filename  = 'input_complex_clean.txt';
out_filename = 'output_fft2d_matlab.txt';

%% 1) 입력 파일 읽기 (hex -> int16 -> Q1.15 실수)
fid = fopen(in_filename, 'r');
if fid == -1
    error('ERROR: cannot open %s', in_filename);
end

% 각 줄: "%h %h" (real imag, 16bit)
data = fscanf(fid, '%x %x', [2, Inf]).';
fclose(fid);

if size(data,1) ~= N*N
    error('Expected %d samples, but got %d', N*N, size(data,1));
end

% hex → uint16 → int16 (2의 보수 부호 해석)
re_u16 = uint16(data(:,1));
im_u16 = uint16(data(:,2));

re_i16 = typecast(re_u16, 'int16');
im_i16 = typecast(im_u16, 'int16');

% Q1.15 → double 실수값으로 변환
x = double(re_i16)/SCALE + 1i*double(im_i16)/SCALE;

% Verilog TB는 16384개를 row-major로 쭉 넣었음
% MATLAB은 column-major라 transpose 한 번 해줘야 동일한 2D 배치
%   [행: chirp index (slow-time)], [열: sample index (fast-time)]
x_frame = reshape(x, [N, N]).';

%% 2) Range FFT (fast-time 방향, 각 행에 대해 128pt FFT)
% Verilog Range_FFT: 결과가 1/N로 스케일된다고 명시되어 있으므로 /N 적용
X_range = fft(x_frame, N, 2) / N;   % dim=2: 열 방향 FFT

% Verilog 코어는 출력이 bit-reversed order
idx_br = bitrevorder(1:N);          % 1-based 인덱스
X_range_br = X_range(:, idx_br);    % 열 인덱스 bit-reverse

%% 3) (전치 버퍼 역할)
% FFT2D_Buffer는
%   - Range FFT 결과를 [row][col]로 쓰고 (row-major)
%   - Doppler FFT 입력을 column-major로 읽어줌
% 구조적으로는 "행 방향 FFT → 열 방향 FFT"와 동치라
% 여기서는 X_range_br에 대해 그대로 열 방향 FFT를 수행하면 됨.

%% 4) Doppler FFT (slow-time 방향, 각 열에 대해 128pt FFT)
X_dopp = fft(X_range_br, N, 1) / N;   % dim=1: 행 방향 FFT + /N 정규화

% Doppler FFT 코어도 1D FFT라 bit-reversed 출력이라고 가정
X_dopp_br = X_dopp(idx_br, :);        % 행 인덱스 bit-reverse

% X_dopp_br의 인덱스 의미:
%   - 행: Doppler 주파수 (bit-reversed)
%   - 열: Range 주파수 (bit-reversed)

%% 5) Q1.15로 양자화 (고정소수점 근사)
Y_real = real(X_dopp_br);
Y_imag = imag(X_dopp_br);

% Q1.15 스케일
Y_real_fx = round(Y_real * SCALE);
Y_imag_fx = round(Y_imag * SCALE);

% Saturation (int16 범위로 제한)
Y_real_fx = min(max(Y_real_fx, -2^(WIDTH-1)), 2^(WIDTH-1)-1);
Y_imag_fx = min(max(Y_imag_fx, -2^(WIDTH-1)), 2^(WIDTH-1)-1);

Y_real_i16 = int16(Y_real_fx);
Y_imag_i16 = int16(Y_imag_fx);

% === ★ 여기가 수정된 부분: typecast 전에 (: )로 1D 벡터화 ===
Y_real_u16 = typecast(Y_real_i16(:), 'uint16');
Y_imag_u16 = typecast(Y_imag_i16(:), 'uint16');

%% 6) 출력 스트림 순서에 맞게 파일로 저장
% Verilog do_en 스트림:
%   - Doppler FFT가 각 열(col)마다 128개씩 순차 출력
%   - column-major 순서로 보는 게 자연스럽고,
% MATLAB의 (:)(column-major) 순서와 일치한다고 가정
fid_out = fopen(out_filename, 'w');
if fid_out == -1
    error('ERROR: cannot open %s for write', out_filename);
end

num_samples = N * N;
for k = 1:num_samples
    fprintf(fid_out, '%04X %04X\n', Y_real_u16(k), Y_imag_u16(k));
end

fclose(fid_out);

disp('MATLAB 2D FFT (Verilog-style) 완료:');
disp(['  입력 : ', in_filename]);
disp(['  출력 : ', out_filename]);
