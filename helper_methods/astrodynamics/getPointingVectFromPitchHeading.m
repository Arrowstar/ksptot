function [vect] = getPointingVectFromPitchHeading(rVect, pitchAngle, headingAngle)
%getPointingVectFromPitchHeading Summary of this function goes here
%   Detailed explanation goes here

    zHat = [0,0,1];

    up = rVect/norm(rVect);
    north = cross(cross(up,zHat),up);
    north = north/norm(north);
    west = cross(up,north);
    west = west/norm(west);

    hP = 2*pi - headingAngle;
    vect = cos(pitchAngle)*(cos(hP)*north + sin(hP)*west) + sin(pitchAngle)*up;
    vect = vect/norm(vect);
end

