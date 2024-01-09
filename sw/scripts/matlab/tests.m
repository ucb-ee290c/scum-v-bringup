
% Test script for interp_saleae function with 3 test cases
% Define Test Case 1
time1 = [0, 1, 3];
data1 = [1, 0, 1];
sample_rate1 = 2; % 2 samples per second
expected_tinterp1 = [0, 0.5, 1, 2, 2.5, 3];
expected_dinterp1 = [1, 1, 0, 0, 0, 1];

% Define Test Case 2
time2 = [0, 2, 4, 5];
data2 = [0, 1, 0, 1];
sample_rate2 = 1; % 1 sample per second
expected_tinterp2 = [0, 1, 2, 3, 4, 5];
expected_dinterp2 = [0, 0, 1, 1, 0, 1];

% Define Test Case 3
time3 = [0, 1.5, 3];
data3 = [0, 1, 0];
sample_rate3 = 4; % 4 samples per second
expected_tinterp3 = [0, 0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75, 3];
expected_dinterp3 = [0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0];

% Run Test Case 1
[tinterp1, dinterp1] = interp_saleae(time1, data1, sample_rate1);
test_passed1 = isequal(tinterp1, expected_tinterp1) && isequal(dinterp1, expected_dinterp1);

% Run Test Case 2
[tinterp2, dinterp2] = interp_saleae(time2, data2, sample_rate2);
test_passed2 = isequal(tinterp2, expected_tinterp2) && isequal(dinterp2, expected_dinterp2);

% Run Test Case 3
[tinterp3, dinterp3] = interp_saleae(time3, data3, sample_rate3);
test_passed3 = isequal(tinterp3, expected_tinterp3) && isequal(dinterp3, expected_dinterp3);

% Display the test results
disp(['Test 1 Passed: ', num2str(test_passed1)]);
disp(['Test 2 Passed: ', num2str(test_passed2)]);
disp(['Test 3 Passed: ', num2str(test_passed3)]);

%%
% Test Case 1: 4-bit
nbits1 = 4;
time4 = 1:(8+nbits1); % Padding with zeros
data4 = [0 0 0 0  0 0 1 0  0 0 1 1  0 0 0 0]; % Padded 4-bit stream
expected_ddec4 = [4, -4]; % Expected output (signed integers)
for shift = 0:nbits1-1
    shifted_data4 = circshift(data4, [0, mod(shift, nbits1)]);
    [tdec4, ddec4] = decode_adc(time4, shifted_data4, nbits1);
    if ~(isequal(ddec4, expected_ddec4))
        disp(['Test Case 1 Shift ' num2str(shift) ' Failed']);
    end
end

% Test Case 2: 6-bit
nbits2 = 6;
time6 = 1:(12+nbits2);
data6 = [0 0 0 0 0 0  1 0 0 1 0 1  0 1 0 1 1 0  0 0 0 0 0 0];
expected_ddec6 = [-23, 26]; % Expected output
for shift = 0:nbits2-1
    shifted_data6 = circshift(data6, [0, mod(shift, nbits2)]);
    [tdec6, ddec6] = decode_adc(time6, shifted_data6, nbits2);
    assert(isequal(ddec6, expected_ddec6), ['Test Case 2 Shift ' num2str(shift) ' Failed']);
end

% Test Case 3: 10-bit
nbits3 = 10;
time10 = 1:(20+nbits3);
data10 = [0 0 0 0 0 0 0 0 0 0  0 1 0 1 0 1 0 1 0 1  1 0 1 0 1 0 1 0 1 0  0 0 0 0 0 0 0 0 0 0];
expected_ddec10 = [341, 682]; % Expected output
for shift = 0:nbits3-1
    shifted_data10 = circshift(data10, [0, mod(shift, nbits3)]);
    [tdec10, ddec10] = decode_adc(time10, shifted_data10, nbits3);
    assert(isequal(ddec10, expected_ddec10), ['Test Case 3 Shift ' num2str(shift) ' Failed']);
end

