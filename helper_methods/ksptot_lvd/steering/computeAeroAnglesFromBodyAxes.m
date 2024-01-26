function [bankAng,angOfAttack,angOfSideslip,totalAoA] = computeAeroAnglesFromBodyAxes(ut, rVect, vVect, bodyInfo, bodyX, bodyY, bodyZ)
    %Source: http://www.dept.aoe.vt.edu/~cdhall/courses/aoe5204/AircraftMotion.pdf   
    [rVectECEF, vVectECEF, R_bodyInertialFrame_to_bodyFixedFrame] = getFixedFrameVectFromInertialVect(ut, rVect, bodyInfo, vVect);

    [R_wind_2_bodyFixedFrame, ~, ~, ~] = computeWindFrame(rVectECEF,vVectECEF);
    R_vehicleBody_2_bodyInertial = horzcat(bodyX, bodyY, bodyZ);
    
    R_bodyFixedFrame_2_bodyInertialFrame = R_bodyInertialFrame_to_bodyFixedFrame';
    R_wind_2_bodyInertialFrame = R_bodyFixedFrame_2_bodyInertialFrame * R_wind_2_bodyFixedFrame;
    R_bodyInertialFrame_2_wind = R_wind_2_bodyInertialFrame';
    angles = rotm2eulARH(R_bodyInertialFrame_2_wind * R_vehicleBody_2_bodyInertial, 'zyx'); %vehicle body frame -> wind frame
    
    angles = real(angles);

    bankAng = angles(3);
	angOfAttack = angles(2);
	angOfSideslip = angles(1);

    [x,y,z] = sph2cart(angleNegPiToPi(angOfSideslip),angleNegPiToPi(angOfAttack),1);
    v1 = [1;0;0];
    v2 = [x;y;z];
    totalAoA = dang(v1,v2);
end