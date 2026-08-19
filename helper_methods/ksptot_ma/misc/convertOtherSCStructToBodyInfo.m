function bodyInfo = convertOtherSCStructToBodyInfo(otherSC, celBodyData)
%convertOtherSCStructToBodyInfo Converts an MA "other spacecraft" struct into a KSPTOT_BodyInfo object.
%   The other spacecraft struct (as stored in maData.spacecraft.otherSC) stores
%   orbital elements relative to its parent body with angular elements in degrees.
%   The returned KSPTOT_BodyInfo is fully wired up with its parent body and
%   celestial body data so that functions like getPositOfBodyWRTSun() and
%   getStateAtTime() can propagate it like any other celestial body.

    arguments
        otherSC struct
        celBodyData
    end

    inputOrbit = [otherSC.sma, otherSC.ecc, deg2rad(otherSC.inc), deg2rad(otherSC.raan), deg2rad(otherSC.arg), deg2rad(otherSC.mean), otherSC.epoch];
    bodyInfo = getBodyInfoStructFromOrbit(inputOrbit);

    bodyInfo.parentid = otherSC.parentID;
    bodyInfo.parent = otherSC.parent;
    bodyInfo.celBodyData = celBodyData;
end
