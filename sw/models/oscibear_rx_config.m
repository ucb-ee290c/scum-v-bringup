close all;
Fs = 2e6;
sim_time = (1/Fs)*1000;
adc_enob = 1;
lgs = sim('oscibear_rx.slx', 'StopTime', num2str(sim_time), 'ReturnWorkspaceOutputs', 'On');

bitsIn = lgs.bitsin.Data(:);
bitsOut = lgs.bitsout.Data(:);

% Plot input and output bits together
figure;
plot(bitsIn, '-*', 'DisplayName', 'Input Bits');
hold on;
plot(bitsOut, '-*', 'DisplayName', 'Output Bits');
hold off;
title('Input and Output Bits');
xlabel('Bit Index');
ylabel('Bit Value');
legend('show');
grid on;

% Plot input and output bits in a separate figure with 1x2 subplots
figure;

subplot(1, 2, 1);
plot(bitsIn, '-*');
title('Input Bits');
xlabel('Bit Index');
ylabel('Bit Value');
grid on;

subplot(1, 2, 2);
plot(bitsOut, '-*');
title('Output Bits');
xlabel('Bit Index');
ylabel('Bit Value');
grid on;

% Calculate Bit Error Rate
bitErrors = sum(bitsIn ~= bitsOut);
totalBits = length(bitsIn);
bitErrorRate = bitErrors / totalBits;

fprintf('Bit Error Rate (BER): %f\n', bitErrorRate);

figure;
complexSignal = lgs.cpmout.Data(:);
% Estimate power spectral density (PSD) using Welch's method
[psd, freq] = pwelch(complexSignal, [], [], [], Fs, 'twosided');
% Plot power spectrum
figure;
plot(freq, 10*log10(psd));
title('Power Spectrum of CPM Modulator Output');
xlabel('Frequency (Hz)');
ylabel('Power Spectral Density (dB/Hz)');
grid on;
