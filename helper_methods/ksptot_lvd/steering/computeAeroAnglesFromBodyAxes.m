function [bankAng,angOfAttack,angOfSideslip] = computeAeroAnglesFromBodyAxes(ut, rVect, vVect, bodyInfo, bodyX, bodyY, bodyZ)
    %Source: http://www.dept.aoe.vt.edu/~cdhall/courses/aoe5204/AircraftMotion.pdf

%     [RVvlh2Inert, vvlh_x, ~, ~] = computeVvlhFrame(rVect,vVect);
%     RVel2Vvlh = computeVelFrameInVvlhFrame(rVect, vVect, vvlh_x);
%     Rtotal = horzcat(bodyX, bodyY, bodyZ);
%     
%     [bankAng,angOfAttack,angOfSideslip] = dcm2angle(RVel2Vvlh' * RVvlh2Inert' * Rtotal, 'xyz');
    
    [rVectECEF, vVectECEF, REci2Ecef] = getFixedFrameVectFromInertialVect(ut, rVect, bodyInfo, vVect);

    [R_wind_2_inert, ~, ~, ~] = computeWindFrame(rVectECEF,vVectECEF);
    Rtotal = horzcat(bodyX, bodyY, bodyZ);
    
    angles = rotm2eulARH((REci2Ecef' * R_wind_2_inert)' * Rtotal, 'xyz');

    bankAng = angles(1);
	angOfAttack = angles(2);
	angOfSideslip = angles(3);
    
    bankAng = real(bankAng);
    angOfAttack = real(angOfAttack);
    angOfSideslip = real(angOfSideslip);
end