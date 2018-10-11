function [bodyX, bodyY, bodyZ, R_total] = computeBodyAxesFromEuler(ut, rVect, vVect, bodyInfo, rollAng, pitchAng, yawAng)

%     R_body_2_vvlh = angle2dcm(yawAng,pitchAng,rollAng,'xyz');
%     [R_vvlh_2_inert, ~, ~, ~] = computeVvlhFrame(rVect,vVect);
% 	R_total = R_vvlh_2_inert * R_body_2_vvlh;

    R_body_2_ned = angle2dcm(yawAng,pitchAng,rollAng,'xyz');
    [R_ned_2_inert, ~, ~, ~] = computeNedFrame(ut, rVect, bodyInfo);
	R_total = R_ned_2_inert * R_body_2_ned;
    
    bodyX = R_total(:,1);
    bodyY = R_total(:,2);
    bodyZ = R_total(:,3);
end