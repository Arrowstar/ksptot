function [R_wind_2_inert, wind_x, wind_y, wind_z] = computeWindFrame(rVect,vVect)
    down = -1*normVector(rVect);
    
    wind_x = normVector(vVect);
    wind_y = normVector(crossARH(down, wind_x));
    wind_z = normVector(crossARH(wind_x, wind_y));
    
    R_wind_2_inert = horzcat(wind_x,wind_y,wind_z);
end