function [R_ned_2_inert, ned_x, ned_y, ned_z] = computeNedFrame(ut, rVectECI, bodyInfo)
    %Source: https://en.wikipedia.org/wiki/North_east_down
    
    [~, ~, REci2Ecef] = getFixedFrameVectFromInertialVect(ut, rVectECI, bodyInfo);
    [phi, lambda] = getLatLongAltFromInertialVect(ut, rVectECI, bodyInfo);
   
    REcef2Ned = [-sin(phi)*cos(lambda), -sin(lambda), -cos(phi)*cos(lambda);
                 -sin(phi)*sin(lambda),  cos(lambda), -cos(phi)*sin(lambda);
                  cos(phi),              0,           -sin(phi)]';
              
    R_ned_2_inert = (REcef2Ned * REci2Ecef)';
    ned_x = R_ned_2_inert(:,1);
    ned_y = R_ned_2_inert(:,2);
    ned_z = R_ned_2_inert(:,3);
end