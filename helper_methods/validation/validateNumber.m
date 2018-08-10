function errMsg = validateNumber(x, numberName, lb, ub, isInt, prevErrMsgs, enteredStr)
%validateNumber Summary of this function goes here
%   Detailed explanation goes here
    
    errMsg=prevErrMsgs;
    if(not(isnumeric(x)) || isnan(x))
        enteredStr = ['(Entered: ', enteredStr, ')'];
        errMsg{end+1} = [numberName, ' must be numeric.  ', enteredStr];
        return;
    end
    
    enteredStr = ['(Entered: ', num2str(x), ')'];

    if(isInt==true)
        if(not(ceil(x) == floor(x)))
            errMsg{end+1} = [numberName, ' must be an integer.  ', enteredStr];
        end
    end
    
    if(x<lb || x>ub)
        rngStr = ['[',num2str(lb), ', ', num2str(ub)   ,']'];
        errMsg{end+1} = [numberName, ' must be within the range ', rngStr, '.  ', enteredStr];
    end
end

