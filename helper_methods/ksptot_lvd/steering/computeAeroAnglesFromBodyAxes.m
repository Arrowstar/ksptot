function [bankAng,angOfAttack,angOfSideslip] = computeAeroAnglesFromBodyAxes(ut, rVect, vVect, bodyInfo, bodyX, bodyY, bodyZ)
    %Source: http://www.dept.aoe.vt.edu/~cdhall/courses/aoe5204/AircraftMotion.pdf   
    [rVectECEF, vVectECEF, REci2Ecef] = getFixedFrameVectFromInertialVect(ut, rVect, bodyInfo, vVect);

    [R_wind_2_inert, ~, ~, ~] = computeWindFrame(rVectECEF,vVectECEF);
    Rtotal = horzcat(bodyX, bodyY, bodyZ);
    
    angles = rotm2eulARH((REci2Ecef' * R_wind_2_inert)' * Rtotal, 'zyx');
    
    angles = real(angles);

    bankAng = angles(3);
	angOfAttack = angles(2);
	angOfSideslip = angles(1);
end