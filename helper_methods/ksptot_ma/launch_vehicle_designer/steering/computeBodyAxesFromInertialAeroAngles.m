function [bodyX, bodyY, bodyZ, Rtotal] = computeBodyAxesFromInertialAeroAngles(ut, rVect, vVect, bodyInfo, angOfAttack, angOfSideslip, bankAng)
    [R_wind_2_inert, ~, ~, ~] = computeWindFrame(rVect,vVect);
    RBody2Wind = eul2rotm([bankAng,angOfAttack,angOfSideslip],'xyz');
    Rtotal = R_wind_2_inert*RBody2Wind;
    
    bodyX = Rtotal(:,1);
    bodyY = Rtotal(:,2);
    bodyZ = Rtotal(:,3);
end