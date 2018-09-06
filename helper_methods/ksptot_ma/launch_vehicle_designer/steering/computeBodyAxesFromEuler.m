function [bodyX, bodyY, bodyZ, R_total] = computeBodyAxesFromEuler(rVect, vVect, rollAng, pitchAng, yawAng)

    R_body_2_vvlh = angle2dcm(rollAng,pitchAng,yawAng,'xyz');
    [R_vvlh_2_inert, ~, ~, ~] = computeVvlhFrame(rVect,vVect);
	R_total = R_vvlh_2_inert * R_body_2_vvlh;
    
    bodyX = R_total(:,1);
    bodyY = R_total(:,2);
    bodyZ = R_total(:,3);
end