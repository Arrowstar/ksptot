function [az, elev, r] = getAzElRngFromNedPosition(nedPosition)
    hypotxy = hypot(nedPosition(1),nedPosition(2));
    r = hypot(hypotxy,-nedPosition(3));
    elev = atan2(-nedPosition(3),hypotxy);
    az = atan2(nedPosition(2),nedPosition(1))-0;
%     az = mod(az,360);
    az = AngleZero2Pi(az);
end