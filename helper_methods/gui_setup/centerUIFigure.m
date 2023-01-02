function centerUIFigure(hUiFig)
    hUiFig.Units = 'normalized';
    pos = hUiFig.Position;
    pos(1) = 0.5 - pos(3)/2;
    pos(2) = 0.5 - pos(4)/2;
    hUiFig.Position = pos;
    hUiFig.Units = 'pixels';
end

