function [tdec,ddec] = decode_adc(time, data, nbits)
    tinterp = time;
    dinterp = data;
    best_delay = 0;
    min_error = Inf;

    for delay = 0:nbits
        ddec = [];
        tdec = [];
    
        for i = delay+1:nbits:(length(dinterp) - nbits)
            ddec(end+1) = reinterpretAsSigned(bin2dec(flip(num2str(dinterp(i:i+nbits-1)))), nbits);
            tdec(end+1) = tinterp(i);
        end
        figure(delay+1); 
        plot(tdec, ddec);
        drawnow
        % Remove outliers outside 10 std
        idx_rem = abs(ddec - mean(ddec)) > 10*std(ddec);
    end
    
    % Decode data using the best delay
    ddec = [];
    tdec = [];
    for i = best_delay+1:nbits:(length(dinterp) - nbits)
        ddec(end+1) = bin2dec(num2str(dinterp(i:i+nbits-1)));
        tdec(end+1) = tinterp(i);
    end
end

