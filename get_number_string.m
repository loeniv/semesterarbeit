function number_string = get_number_string(nmax,i)
%GET_NUMBER_STRING Summary of this function goes here
%   Detailed explanation goes here
    % Calculate the number of digits in the maximum number
    numDigits = length(num2str(nmax));
    
    % Create the format string for leading zeros
    formatString = sprintf('%%0%dd', numDigits);
    
    % Create the number string with leading zeros
    number_string = sprintf(formatString, i);
end

