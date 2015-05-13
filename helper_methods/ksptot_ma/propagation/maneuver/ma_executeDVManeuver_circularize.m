function eventLog = ma_executeDVManeuver_circularize(thruster, initialState, eventNum, celBodyData)
%ma_executeDVManeuver_circularize Summary of this function goes here
%   Detailed explanation goes here
    bodyID = initialState(8);
    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    gmu = bodyInfo.gm;

    rVect = initialState(2:4)';
    vVect = initialState(5:7);
    hVect = cross(rVect,vVect);

    vC = sqrt(gmu/norm(rVect));
    vVectNew = cross(hVect, rVect);
    vVectNew = vC*(vVectNew/norm(vVectNew));
    
    dv = vVectNew - vVect;
    eventLog = ma_executeDVManeuver_dv_inertial(dv', thruster, initialState, eventNum);
end

