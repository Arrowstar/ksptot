function angleNew = angleNegPiToPi(angle)
%angleNegPiToPi Summary of this function goes here
%   Detailed explanation goes here
    angleNew = AngleZero2Pi(angle);
    if(angleNew > pi)
        angleNew = angleNew - 2*pi;
    end
end

