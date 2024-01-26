function [bodyX, bodyY, bodyZ, R_total] = computeBodyAxesFromEuler(ut, rVect, vVect, bodyInfo, rollAng, pitchAng, yawAng)   
    R_vehBody_2_ned = eul2rotmARH_mex([yawAng,pitchAng,rollAng],'zyx'); %Vehicle Body Frame -> NED
    [R_ned_2_bodyInertial, ~, ~, ~] = computeNedFrame(ut, rVect, bodyInfo); %NED -> Body Inertial
	R_total = R_ned_2_bodyInertial * R_vehBody_2_ned; % Vehicle body -> body inertial
    
    bodyX = R_total(:,1);
    bodyY = R_total(:,2);
    bodyZ = R_total(:,3);
end