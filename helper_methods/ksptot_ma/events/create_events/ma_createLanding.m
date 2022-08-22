function landing = ma_createLanding(name, landingDuration, lineColor, lineStyle, lineWidth, massLoss)
%ma_createDocking Summary of this function goes here
%   Detailed explanation goes here

    landing = struct();

    landing.id              = rand(1);
    landing.type            = 'Landing';
    landing.name            = name;
    landing.landingDuration	= landingDuration;
    landing.lineColor       = lineColor;
    landing.lineStyle       = lineStyle;
    landing.lineWidth       = lineWidth;
    landing.massloss        = massLoss;
end

