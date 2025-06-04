%% 1. 기본 파라미터
N = 64;                          % FFT 포인트 수
fc = 24e9;                       % 중심 주파수 24GHz
c = physconst('LightSpeed');    % 광속
BW = 4e9;                        % FMCW 대역폭
T_chirp = 40e-6;                 % Chirp duration
slope = BW / T_chirp;
t = linspace(0, T_chirp, N);    % Fast time (ADC 샘플)

%% 2. 타겟 거리 기반 FMCW 신호 생성
R = 1.2;                         % 타겟 거리 (m)
tau = 2 * R / c;                 % 왕복 지연 시간

% Tx / Rx 시그널
tx = exp(1j * 2 * pi * (fc * t + 0.5 * slope * t.^2));
rx = exp(1j * 2 * pi * (fc * (t - tau) + 0.5 * slope * (t - tau).^2));

% IF 신호 (복소수)
if_signal = tx .* conj(rx);

%% 3. Q1.15 고정소수점 스케일링
scale = 2^15;
re_fixed = round(real(if_signal) * scale);
im_fixed = round(imag(if_signal) * scale);

% 16-bit 정수 범위 제한
re_fixed = min(max(re_fixed, -2^15), 2^15 - 1);
im_fixed = min(max(im_fixed, -2^15), 2^15 - 1);

%% 4. Verilog용 입력 파일 저장 (hex)
fid = fopen('if_input.txt', 'w');
for i = 1:N
    re_hex = typecast(int16(re_fixed(i)), 'uint16');
    im_hex = typecast(int16(im_fixed(i)), 'uint16');
    fprintf(fid, '%04x %04x\n', re_hex, im_hex);  % real imag 순서
end
fclose(fid);

disp('[✔] if_input.txt 저장 완료: Verilog 테스트벤치 입력으로 사용 가능');
