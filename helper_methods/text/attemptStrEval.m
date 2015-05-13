function [strOut] = attemptStrEval(strIn)
    if(length(strIn) == length(regexp(strIn, '[eE0-9+\-*/\s\.]')))
        try
            strOut = num2str(eval(strIn),15);
        catch ME
            strOut = strIn;
        end
    else
        strOut = strIn;
    end
end

