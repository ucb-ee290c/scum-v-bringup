function output = reinterpretAsSigned(input, bitWidth)
    % Determine if the input is negative (MSB is 1)
    if bitget(input, bitWidth) == 1
        % Convert to negative by subtracting from 2^bitWidth
        output = input - bitshift(1, bitWidth);
    else
        output = input;
    end
end