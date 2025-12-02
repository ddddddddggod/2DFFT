%% ---------------------------------------------------------
%  2D FFT용 복소 입력 생성 (128x128)
%  - 깨끗한 정현파 복소수 (노이즈 X, 랜덤 X)
%  - 각 sample: Q1.15 16bit 정수
%  - 한 줄: "RRRR IIII" (Real Imag, HEX)
%  - 파일: input_complex_clean.txt
% ----------------------------------------------------------
clear; clc;

N = 128;    % 한 프레임당 포인트 수 (range 방향)
M = 128;    % 프레임 수 (doppler 방향)

WIDTH   = 16;
MAX_Q15 = 2^(WIDTH-1) - 1;   % 32767

% 결과 저장용 (정수 Q1.15)
real_frame = zeros(M, N);
imag_frame = zeros(M, N);

t = 0:N-1;   % 시간축 인덱스

% ---------------------------------------------------------
%  깨끗한 정현파 파라미터 설정
%  - f: range 방향에서의 주파수 (0~N-1 중 하나, DC는 0)
%  - phi: 초기 위상
%  주파수/위상 바꾸고 싶으면 여기만 수정하면 됨!
% ---------------------------------------------------------
f   = 4;          % 예: 4-bin 톤 (원하면 1~20 사이 등으로 바꿔도 됨)
phi = 0;          % 위상 0 (원하면 pi/4, pi/2 등)

% ---------------------------------------------------------
%  모든 프레임에 동일한 복소 정현파를 사용
%  sig_re = sin, sig_im = cos (크기 1, 노이즈 없음)
% ---------------------------------------------------------
for m = 1:M
    sig_re = sin(2*pi*f/N * t + phi);   % Real part
    sig_im = cos(2*pi*f/N * t + phi);   % Imag part

    % [-1, 1] 범위라서 사실상 정규화 필요 없음. 아래는 안전용.
    max_abs = max( [max(abs(sig_re)), max(abs(sig_im))] );
    if max_abs < 1e-6
        max_abs = 1;
    end
    sig_re_n = sig_re / max_abs;
    sig_im_n = sig_im / max_abs;

    % Q1.15 정수로 스케일링 (16-bit signed)
    real_q15 = round(sig_re_n * MAX_Q15);
    imag_q15 = round(sig_im_n * MAX_Q15);

    real_frame(m,:) = real_q15;
    imag_frame(m,:) = imag_q15;
end

%% ---------------------------------------------------------
%  텍스트 파일로 저장 (Real HEX, Imag HEX 한 줄씩)
% ----------------------------------------------------------
fid = fopen('input_complex_clean.txt', 'w');

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

disp('✓ input_complex_clean.txt 생성 완료!');

%% ---------------------------------------------------------
%  (옵션) 입력 파형 그래프로 확인
%   - Frame 1 기준 Real/Imag (정수) + 정규화된 파형
% ----------------------------------------------------------
frame_idx = 1;  % 보고 싶은 프레임 인덱스

figure;

% 정수(Q15) 그대로
subplot(3,1,1);
plot(0:N-1, real_frame(frame_idx,:), '-o');
title(sprintf('Frame %d - Real (Q1.15 정수)', frame_idx));
xlabel('Sample index');
ylabel('Q15 value');
grid on;

subplot(3,1,2);
plot(0:N-1, imag_frame(frame_idx,:), '-o');
title(sprintf('Frame %d - Imag (Q1.15 정수)', frame_idx));
xlabel('Sample index');
ylabel('Q15 value');
grid on;

% 정규화해서 [-1,1]로 다시 본 파형
subplot(3,1,3);
real_norm = double(real_frame(frame_idx,:)) / double(MAX_Q15);
imag_norm = double(imag_frame(frame_idx,:)) / double(MAX_Q15);
plot(0:N-1, real_norm, '-');
hold on;
plot(0:N-1, imag_norm, '--');
hold off;
legend('Real (norm)', 'Imag (norm)');
title(sprintf('Frame %d - Normalized Waveform', frame_idx));
xlabel('Sample index');
ylabel('Amplitude');
grid on;
