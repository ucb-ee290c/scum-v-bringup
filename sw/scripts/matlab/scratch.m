data = importdata("500m_10hz_250moff_001010_idac_32mhz.csv");
sps = 32e6;
%%
npts = 1e6;
t = data.data(1:npts,1);
d = data.data(1:npts,2);

[tinterp, dinterp] = interp_saleae(t, d, sps);

% Plot the result
figure;
stem(tinterp, dinterp);

% Now, sliding window of nbits to decode the data
%%
nbits = 20;
best_delay = 0;
min_error = Inf;

[tdec, ddec] = decode_adc(tinterp, dinterp, nbits);

% Plot the result
figure;
plot(tdec, ddec);
title(['Decoded Data with Best Delay: ', num2str(best_delay)]);

figure;
plot(tdec, ddec);