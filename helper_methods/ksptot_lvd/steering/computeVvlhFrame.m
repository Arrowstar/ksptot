function [R_vvlh_2_inert, vvlh_x, vvlh_y, vvlh_z] = computeVvlhFrame(rVect,vVect)
    %Source: http://help.agi.com/stk/index.htm#gator/eq-coordsys.htm#vnc
    vvlh_z = -rVect/norm(rVect);
    vvlh_y = -cross(rVect,vVect)/norm(cross(rVect,vVect));
    vvlh_x = cross(vvlh_y,vvlh_z)/norm(cross(vvlh_y,vvlh_z));
    
    R_vvlh_2_inert = horzcat(vvlh_x,vvlh_y,vvlh_z);
end