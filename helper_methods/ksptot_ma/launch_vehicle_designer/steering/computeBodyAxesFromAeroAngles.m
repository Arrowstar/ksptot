function [bodyX, bodyY, bodyZ, Rtotal] = computeBodyAxesFromAeroAngles(rVect, vVect, angOfAttack, angOfSideslip, bankAng)
    %Source: http://www.dept.aoe.vt.edu/~cdhall/courses/aoe5204/AircraftMotion.pdf

    [RVvlh2Inert, vvlh_x, ~, ~] = computeVvlhFrame(rVect,vVect);
    RVel2Vvlh = computeVelFrameInVvlhFrame(rVect, vVect, vvlh_x);
    RBody2Vel = angle2dcm(bankAng,angOfAttack,angOfSideslip,'xyz');
       
    Rtotal = RVvlh2Inert*RVel2Vvlh*RBody2Vel;
    
    bodyX = Rtotal(:,1);
    bodyY = Rtotal(:,2);
    bodyZ = Rtotal(:,3);
end