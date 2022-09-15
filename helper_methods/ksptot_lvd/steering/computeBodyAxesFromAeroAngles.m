function [bodyX, bodyY, bodyZ, Rtotal] = computeBodyAxesFromAeroAngles(ut, rVect, vVect, bodyInfo, angOfAttack, angOfSideslip, bankAng)
    %Source: http://www.dept.aoe.vt.edu/~cdhall/courses/aoe5204/AircraftMotion.pdf

%     [RVvlh2Inert, vvlh_x, ~, ~] = computeVvlhFrame(rVect,vVect);
%     RVel2Vvlh = computeVelFrameInVvlhFrame(rVect, vVect, vvlh_x);
%     RBody2Vel = angle2dcm(bankAng,angOfAttack,angOfSideslip,'xyz');
%        
%     Rtotal = RVvlh2Inert*RVel2Vvlh*RBody2Vel;

    [rVectECEF, vVectECEF, REci2Ecef] = getFixedFrameVectFromInertialVect(ut, rVect, bodyInfo, vVect);

    [R_wind_2_ecef, ~, ~, ~] = computeWindFrame(rVectECEF,vVectECEF);
    RBody2Wind = eul2rotmARH_mex([angOfSideslip,angOfAttack,bankAng],'zyx');
    Rtotal = REci2Ecef' * R_wind_2_ecef * RBody2Wind; %body to wind -> wind to ecef -> ecef -> inertial
    
    bodyX = Rtotal(:,1);
    bodyY = Rtotal(:,2);
    bodyZ = Rtotal(:,3);
end