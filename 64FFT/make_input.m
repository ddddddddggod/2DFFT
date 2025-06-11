% === Verilog용 Q1.15 정현파 입력 생성 (Real + Imag = 0000) ===
N = 64;                     % FFT 크기
A = 0.9;                    % 진폭 (오버플로 방지)
f = 5;                      % 사인파 주기 (N 샘플 내에서 f회 반복)
n = 0:N-1;

sig = A * sin(2*pi*f*n/N);  % 정현파 신호 생성 (실수 성분만 있음)

% Q1.15 고정소수점으로 변환
q15_scale = 2^15;
sig_q15 = round(sig * q15_scale);
sig_q15(sig_q15 < 0) = sig_q15(sig_q15 < 0) + 2^16;  % 2's complement wrap to unsigned 16-bit

% 텍스트 파일로 저장 (real imag 쌍, imag는 항상 0000)
fileID = fopen('if_input2.txt', 'w');
for i = 1:N
    fprintf(fileID, '%04X 0000\n', sig_q15(i));
end
fclose(fileID);

% 시각화 (선택)
figure;
plot(n, sig, 'o-');
title('입력 정현파'); xlabel('n'); ylabel('Amplitude'); grid on;




