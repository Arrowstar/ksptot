function docking = ma_createDocking(name, oScId, undockTime, lineColor, lineStyle, massLoss)
%ma_createDocking Summary of this function goes here
%   Detailed explanation goes here

    docking = struct();

    docking.id          = rand(1);
    docking.type        = 'Docking';
    docking.name        = name;
    docking.oScId       = oScId;
    docking.undockTime	= undockTime;
    docking.lineColor   = lineColor;
    docking.lineStyle   = lineStyle;
    docking.massloss	= massLoss;
end

