function [stateLogCol] = ma_resNumToStateLogCol(resNum)
%ma_resNumToStateLogCol Summary of this function goes here
%   Detailed explanation goes here

    switch resNum
        case 1
            stateLogCol = 10;
        case 2
            stateLogCol = 11;
        case 3
            stateLogCol = 12;
        otherwise
            error('Resource number %u has no mapping to a state log column number!', resNum);
    end

end

