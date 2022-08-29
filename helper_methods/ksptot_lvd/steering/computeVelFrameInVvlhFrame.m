function RVel2Vvlh = computeVelFrameInVvlhFrame(rVect, vVect, vvlh_x)
    %Source: http://www.dept.aoe.vt.edu/~cdhall/courses/aoe5204/AircraftMotion.pdf

    rHat = -rVect/norm(rVect);
    velProjVvlhXyPlane = vVect - dot(vVect,rHat)*rHat;
    
    h = norm(cross(rVect,vVect));
    vFPA = real(acos(h/(norm(rVect)*norm(vVect))));
    hFPA = dang(vvlh_x,velProjVvlhXyPlane);
    if(dot(rVect,cross(vvlh_x,velProjVvlhXyPlane)) < 0)
        hFPA = -hFPA;
    end
    hFPA = 0;
    
    RVel2Vvlh = dcmbody2wind(vFPA, hFPA); 
end