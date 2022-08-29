function [bankAng,angOfAttack,angOfSideslip,totalAoA] = computeAeroAnglesFromFrameBodyAxes(rVectFrame, vVectFrame, bodyXFrame, bodyYFrame, bodyZFrame)
    %Source: http://www.dept.aoe.vt.edu/~cdhall/courses/aoe5204/AircraftMotion.pdf   

    [R_wind_2_frame, ~, ~, ~] = computeWindFrame(rVectFrame, vVectFrame);
    R_body_2_frame = horzcat(bodyXFrame, bodyYFrame, bodyZFrame);
    
    angles = real(rotm2eulARH(R_wind_2_frame' * R_body_2_frame, 'zyx'));
 
    bankAng = angles(3);
	angOfAttack = angles(2);
	angOfSideslip = angles(1);

    [x,y,z] = sph2cart(angleNegPiToPi_mex(angOfSideslip),angleNegPiToPi_mex(angOfAttack),1);
    v1 = [1;0;0];
    v2 = [x;y;z];
    totalAoA = dang(v1,v2);
end