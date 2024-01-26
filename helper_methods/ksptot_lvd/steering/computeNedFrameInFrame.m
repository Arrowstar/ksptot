function [R_ned_2_frame, ned_x, ned_y, ned_z] = computeNedFrameInFrame(rVect)
    %Source: https://en.wikipedia.org/wiki/North_east_down
    %Returns the rotation from the NED frame to the frame that rVect is in.
    
    rNorm = norm(rVect);
    lambda = AngleZero2Pi(atan2(rVect(2),rVect(1)));
    phi = pi/2 - acos(rVect(3)/rNorm);
   
    RFrame2Ned = [-sin(phi)*cos(lambda), -sin(lambda), -cos(phi)*cos(lambda);
                 -sin(phi)*sin(lambda),  cos(lambda), -cos(phi)*sin(lambda);
                  cos(phi),              0,           -sin(phi)]';
              
    R_ned_2_frame = RFrame2Ned';
    ned_x = R_ned_2_frame(:,1);
    ned_y = R_ned_2_frame(:,2);
    ned_z = R_ned_2_frame(:,3);
end