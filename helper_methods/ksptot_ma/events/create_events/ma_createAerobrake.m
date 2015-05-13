function aerobrake = ma_createAerobrake(name, dragCoeff, dragModel)
%ma_createAerobrake Summary of this function goes here
%   Detailed explanation goes here

    aerobrake = struct();
    aerobrake.name	    = name;
    aerobrake.type      = 'Aerobrake';
    aerobrake.dragCoeff = dragCoeff;
    aerobrake.dragModel = dragModel;
    aerobrake.id        = rand(1);
end

