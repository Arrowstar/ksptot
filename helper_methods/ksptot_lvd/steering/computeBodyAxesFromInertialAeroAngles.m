function [bodyX, bodyY, bodyZ, Rtotal] = computeBodyAxesFromInertialAeroAngles(~, rVect, vVect, ~, angOfAttack, angOfSideslip, bankAng)
    [R_wind_2_bodyInertial, ~, ~, ~] = computeWindFrame(rVect,vVect); %Wind frame -> body inertial frame
    R_vehBodyFrame_2_WindFrame = eul2rotmARH_mex([angOfSideslip,angOfAttack,bankAng],'zyx'); %Vehicle body frame to wind frame
    Rtotal = R_wind_2_bodyInertial * R_vehBodyFrame_2_WindFrame; %vehicle body frame -> body_inertial
    
    bodyX = Rtotal(:,1);
    bodyY = Rtotal(:,2);
    bodyZ = Rtotal(:,3);
end