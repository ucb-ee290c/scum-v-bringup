% Specify the file name (adjust the path as necessary)
filename = '..\python\logs\counter_regs_100m_25m_150mv_p_offset_idac_16.txt';
% filename = '..\python\logs\counter_regs_100m_25m_25mv_n_offset_idac_16.txt';
% Open the file for reading
fid = fopen(filename, 'rt');
if fid == -1
    error('Cannot open file: %s', filename);
end

% Initialize arrays to hold the counter values
counter_p = [];
counter_n = [];

N = 128;
% Read the file line by line
n = 1;
while n <= N
    line = fgetl(fid);
    if line == -1
        break; % End of file
    end
    % Look for lines containing CNT_P and CNT_N values
    tokens = sscanf(line, 'CNT_N: %d CNT_P: %d');
    if numel(tokens) == 2
        % Append the values to the arrays
        counter_n(end+1) = tokens(2);
        counter_p(end+1) = tokens(1);
        n = n+1;
    end
    
end

% Close the file
fclose(fid);

diff_p = zeros(1,N);
diff_n = zeros(1,N);



% Calculate the differences
lastp = 0;
lastn = 0;
lastdp = 0;
lastdn = 0;
for i = 1:N
    p = counter_p(i); 
    n = counter_n(i);
    if(p < lastp)
        dp = (p+63) - lastp;
    else
        dp = p - lastp;
    end
    if(n < lastn)
        dn = (n+63) - lastn;
    else
        dn = n - lastn;
    end
    lastp = p;
    lastn = n;
    % if(dp < lastdp/2)
    %     dp = dp*3;
    % end
    % if(dn < lastdn/2)
    %     dn = dn*3;
    % end
    diff_p(i) = dp * 20e6;
    diff_n(i) = dn * 20e6;
    lastdp = dp;
    lastdn = dn;

end

diff_p = mod(diff(counter_p), 63) * 25e6;
diff_n = mod(diff(counter_n), 63) * 25e6;

diff_pm = movmean(diff_p, 8);
diff_nm = movmean(diff_n, 8);


% Plot the raw counter data
figure(1);
subplot(3,1,1);
plot(counter_p, '-o');
hold on;
plot(counter_n, '-o');
hold off;
title('Raw Counter Data');
xlabel('Sample');
ylabel('Value');
legend('CNT_P', 'CNT_N');

% Plot the differences
subplot(3,1,2);
plot(diff_p, '-o');
hold on;
plot(diff_n, '-o');
hold off;
title('Differences in Counter Data');
xlabel('Sample');
ylabel('Difference');
legend('Diff CNT_P', 'Diff CNT_N');


% Plot the differences
subplot(3,1,3);
plot(diff_pm);
hold on;
plot(diff_nm);
hold off;
title('Moving Average Meaned Frequency');
xlabel('Sample');
ylabel('Meaned Difference');
legend('Diff CNT_P', 'Diff CNT_N');

