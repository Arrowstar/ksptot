function angle = AngleZero2Pi(angle)
% Accepts a radian measure angle and returns that angle between 0 and 2*pi.
% Angle is a scalar input, measured in radians.

    angle = abs(mod(real(angle),2*pi));
end