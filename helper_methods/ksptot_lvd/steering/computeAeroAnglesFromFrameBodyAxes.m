function [bankAng,angOfAttack,angOfSideslip,totalAoA] = computeAeroAnglesFromFrameBodyAxes(rVectFrame, vVectFrame, bodyXFrame, bodyYFrame, bodyZFrame)
    %Source: http://www.dept.aoe.vt.edu/~cdhall/courses/aoe5204/AircraftMotion.pdf   

    [R_wind_2_frame, ~, ~, ~] = computeWindFrame(rVectFrame, vVectFrame);
    R_body_2_frame = horzcat(bodyXFrame, bodyYFrame, bodyZFrame);
    
    R = R_wind_2_frame' * R_body_2_frame;
    
    sy = sqrt(R(1,1).*R(1,1) + R(2,1).*R(2,1));
    if(sy < 10*eps(class(R)))
        angOfSideslip = 0;
        angOfAttack = atan2(-R(3,1), sy);
        bankAng = atan2(-R(2,3), R(2,2));
    else
        angOfSideslip = atan2(R(2,1), R(1,1));
        angOfAttack = atan2(-R(3,1), sy);
        bankAng = atan2(R(3,2), R(3,3));
    end

    [x,y,z] = sph2cart(angleNegPiToPi_mex(angOfSideslip),angleNegPiToPi_mex(angOfAttack),1);
    v1 = [1;0;0];
    v2 = [x;y;z];
    totalAoA = dang(v1,v2);
end