function [strOut] = attemptStrEval(strIn)
    if(length(strIn) == length(regexp(strIn, '[eE0-9+\-*/\s\.\(\)\^[sqrt][sin][cos][tan][asin][acos][atan][csc][sec][cot][acsc][asec][acot][sind][cosd][tand][asind][acosd][atand][cscd][secd][cotd][acscd][asecd][acotd][pi][log][log10][log2][eps]]')))
        try
            strOut = stripzeros(num2str(eval(strIn),'%.15f'));
        catch ME
            strOut = strIn;
        end
    else
        strOut = strIn;
    end
end

