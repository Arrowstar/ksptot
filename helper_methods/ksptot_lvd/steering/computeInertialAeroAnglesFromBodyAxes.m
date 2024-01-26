function [bankAng,angOfAttack,angOfSideslip] = computeInertialAeroAnglesFromBodyAxes(ut, rVect, vVect, bodyInfo, bodyX, bodyY, bodyZ)
    %Source: http://www.dept.aoe.vt.edu/~cdhall/courses/aoe5204/AircraftMotion.pdf

    [R_wind_2_bodyinertial, ~, ~, ~] = computeWindFrame(rVect,vVect);
    R_vehicleBody_2_bodyInertial = horzcat(bodyX, bodyY, bodyZ);
    
    angles = rotm2eulARH(R_wind_2_bodyinertial' * R_vehicleBody_2_bodyInertial, 'zyx'); %Vehicle Body Frame -> Wind Frame

    angles = real(angles);
    
    bankAng = angles(3);
	angOfAttack = angles(2);
	angOfSideslip = angles(1);
end