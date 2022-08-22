function angleNew = angleNegPiToPi(angle)
%angleNegPiToPi Summary of this function goes here
%   Detailed explanation goes here
    angleNew = AngleZero2Pi(angle);
    angleNew(angleNew > pi) = angleNew(angleNew > pi) - 2*pi;
end