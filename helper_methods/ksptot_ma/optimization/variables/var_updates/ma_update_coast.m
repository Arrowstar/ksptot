function coast = ma_update_coast(coast, newCoastVal)
%ma_update_coast Summary of this function goes here
%   Detailed explanation goes here

    activeVars = coast.vars(1,:) == 1;
    if(strcmpi(coast.type,'Coast') || strcmpi(coast.type,'NBodyCoast'))
        coast.coastToValue(activeVars) = newCoastVal;
    else
        error(['Could not update coast, it was of the wrong type: ', coast.type]);
    end
end

