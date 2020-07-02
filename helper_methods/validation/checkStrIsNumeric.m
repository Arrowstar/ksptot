function [isNumeric] = checkStrIsNumeric(str)
%checkStrIsNumeric Summary of this function goes here
%   Detailed explanation goes here
    isNumeric = false;

    if(isa(str2double(str),'numeric') && ~isnan(str2double(str))) 
        isNumeric = true;
    else
        isNumeric = false;
    end    
end

