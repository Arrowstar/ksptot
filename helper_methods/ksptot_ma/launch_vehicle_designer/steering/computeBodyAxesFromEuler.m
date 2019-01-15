function [bodyX, bodyY, bodyZ, R_total] = computeBodyAxesFromEuler(ut, rVect, vVect, bodyInfo, rollAng, pitchAng, yawAng)

    R_body_2_ned = eul2rotm([yawAng,pitchAng,rollAng],'zyx');
    [R_ned_2_inert, ~, ~, ~] = computeNedFrame(ut, rVect, bodyInfo);
	R_total = R_ned_2_inert * R_body_2_ned;
    
    bodyX = R_total(:,1);
    bodyY = R_total(:,2);
    bodyZ = R_total(:,3);
end