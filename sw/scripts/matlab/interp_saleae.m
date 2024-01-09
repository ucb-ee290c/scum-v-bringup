function [tinterp, dinterp] = interp_saleae(time, data, sample_rate)
    t = time; 
    d = data;
    
    % Estimate the total number of points needed for preallocation
    dt = diff(t);
    total_pts = round(sum(round(dt * sample_rate)) * 1.1);  % +1 for the initial point
    tinterp = zeros(1, total_pts);
    dinterp = zeros(1, total_pts);
    
    % Initialize indices for filling in the arrays
    fill_idx = 1;
    final_idx = 1;
    % Loop through the data
    for i = 2:length(t)
        dt = t(i) - t(i-1);
        ninterp = round(dt * sample_rate); 
        final_idx =  fill_idx+ninterp-1; 
        terp = linspace(t(i-1), t(i), ninterp + 1);
        tinterp(fill_idx:final_idx) = terp(1:end-1);
        dinterp(fill_idx:final_idx) = d(i-1);
        fill_idx = fill_idx + ninterp;
    end
    
    % Trim the excess zeros
    tinterp = tinterp(1:final_idx);
    dinterp = dinterp(1:final_idx);

end