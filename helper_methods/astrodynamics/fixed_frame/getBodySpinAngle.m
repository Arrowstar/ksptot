function [spinAngle] = getBodySpinAngle(bodyInfo, ut)
%getBodySpinAngle Summary of this function goes here
%   Detailed explanation goes here

    bodySpinRate = 2*pi/bodyInfo.rotperiod; %rad/sec
    rotInit = deg2rad(bodyInfo.rotini);     %rad
    spinAngle = AngleZero2Pi(rotInit + bodySpinRate*ut); %theta)
end

