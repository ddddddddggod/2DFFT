%% ---------------------------------------------------------
%  2D FFT용 복소 입력 생성 (128x128)
%  - 각 sample: Q1.15 16bit 정수
%  - 한 줄: "RRRR IIII" (Real Imag, HEX)
%  - 파일: input_complex.txt
% ----------------------------------------------------------
clear; clc;

N = 128;    % 한 프레임당 포인트 수 (range 방향)
M = 128;    % 프레임 수 (doppler 방향)

WIDTH = 16;
MAX_Q15 = 2^(WIDTH-1) - 1;   % 32767

rng(1);  % 재현 가능하도록 시드 고정 (원하면 바꿔도 됨)

% 결과 저장용
real_frame = zeros(M, N);
imag_frame = zeros(M, N);

t = 0:N-1;   % 시간축 인덱스

for m = 1:M
    % ------------------------------------------------------
    % 1) 각 프레임마다 랜덤한 주파수/위상 선택
    % ------------------------------------------------------
    f1   = randi([1 20]);      % 첫 번째 사인파 주파수
    f2   = randi([1 20]);      % 두 번째 사인파 주파수
    phi1 = 2*pi*rand;          % 랜덤 위상 1
    phi2 = 2*pi*rand;          % 랜덤 위상 2

    % 기본 사인/코사인 조합 (사인파 형태)
    sig_re = 0.7 * sin(2*pi*f1/N * t + phi1) + ...
             0.3 * sin(2*pi*f2/N * t + phi2);

    sig_im = 0.6 * cos(2*pi*f1/N * t + phi2) - ...
             0.4 * sin(2*pi*f2/N * t + phi1);

    % 약간의 노이즈 추가 (원하면 0으로 줄여도 됨)
    noise_level = 0.05;
    sig_re = sig_re + noise_level * randn(size(sig_re));
    sig_im = sig_im + noise_level * randn(size(sig_im));

    % ------------------------------------------------------
    % 2) [-1, 1] 범위로 정규화
    % ------------------------------------------------------
    max_abs = max( [max(abs(sig_re)), max(abs(sig_im))] );
    if max_abs < 1e-6
        max_abs = 1;
    end
    sig_re_n = sig_re / max_abs;
    sig_im_n = sig_im / max_abs;

    % ------------------------------------------------------
    % 3) Q1.15 정수로 스케일링 (16-bit signed)
    % ------------------------------------------------------
    real_q15 = round(sig_re_n * MAX_Q15);
    imag_q15 = round(sig_im_n * MAX_Q15);

    real_frame(m,:) = real_q15;
    imag_frame(m,:) = imag_q15;
end

%% ---------------------------------------------------------
%  4) 텍스트 파일로 저장 (Real HEX, Imag HEX 한 줄씩)
% ----------------------------------------------------------
fid = fopen('input_complex.txt', 'w');

for r = 1:M
    for c = 1:N
        % int16 -> uint16으로 비트 패턴 유지 후 HEX 변환
        real_hex = dec2hex( typecast(int16(real_frame(r,c)), 'uint16'), 4);
        imag_hex = dec2hex( typecast(int16(imag_frame(r,c)), 'uint16'), 4);

        % "RRRR IIII" 형식으로 저장
        fprintf(fid, '%s %s\n', real_hex, imag_hex);
    end
end

fclose(fid);

disp('✓ input_complex.txt 생성 완료!');
