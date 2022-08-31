function [bodyX, bodyY, bodyZ, Rtotal] = computeBodyAxesFromInertialAeroAngles(~, rVect, vVect, ~, angOfAttack, angOfSideslip, bankAng)
    [R_wind_2_inert, ~, ~, ~] = computeWindFrame(rVect,vVect);
    RBody2Wind = eul2rotmARH([angOfSideslip,angOfAttack,bankAng],'zyx');
    Rtotal = R_wind_2_inert*RBody2Wind;
    
    bodyX = Rtotal(:,1);
    bodyY = Rtotal(:,2);
    bodyZ = Rtotal(:,3);
end