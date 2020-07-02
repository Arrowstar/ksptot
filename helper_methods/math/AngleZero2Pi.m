function Angle = AngleZero2Pi(Angle)
% Accepts a radian measure angle and returns that angle between 0 and 2*pi.
% Angle is a scalar input, measured in radians.

Angle = abs(mod(real(Angle),2*pi));