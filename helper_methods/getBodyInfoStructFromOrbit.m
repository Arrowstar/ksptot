function [bodyInfo] = getBodyInfoStructFromOrbit(inputOrbit)
%getBodyInfoStructFromOrbit Summary of this function goes here
%   Detailed explanation goes here

%     bodyInfo = struct();
    bodyInfo = KSPTOT_BodyInfo();
    bodyInfo.epoch = inputOrbit(7);
    bodyInfo.sma = inputOrbit(1);
    bodyInfo.ecc = inputOrbit(2);
    bodyInfo.inc = rad2deg(inputOrbit(3));
    bodyInfo.raan = rad2deg(inputOrbit(4));
    bodyInfo.arg = rad2deg(inputOrbit(5));
    bodyInfo.mean = rad2deg(inputOrbit(6));
    bodyInfo.id = rand();
    bodyInfo.propTypeEnum = BodyPropagationTypeEnum.TwoBody;
end

