function [deltaVStrName] = deltaVTypeEnum(deltaVTypeTag)
%deltaVTypeEnum Summary of this function goes here
%   Detailed explanation goes here

switch(deltaVTypeTag)
    case 'departDVRadioBtn'
        deltaVStrName = 'Departure Delta-V Only';
    case 'arrivalDVRadioBtn'
        deltaVStrName = 'Arrival Delta-V Only';
    case 'departPArrivalDVRadioBtn'
        deltaVStrName = 'Departure + Arrival Delta-V';
    otherwise
        error('Delta-V type not found.');
end

end

