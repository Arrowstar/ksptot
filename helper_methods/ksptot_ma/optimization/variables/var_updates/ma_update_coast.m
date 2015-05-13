function coast = ma_update_coast(coast, newCoastVal)
%ma_update_coast Summary of this function goes here
%   Detailed explanation goes here

    if(strcmpi(coast.type,'Coast'))
        coast.coastToValue = newCoastVal;
    else
        error(['Could not update coast, it was of the wrong type: ', coast.type]);
    end
end

