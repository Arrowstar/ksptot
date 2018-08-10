function lvlhCurviPosDeputy = computeLvlhCurviPos(rVectInertChief, vVectInertChief, rVectChiefToDeputy, gmuChief)
%computeLvlhCurviPos See page 50 of SM-2013-NicholasAustin.pdf
%   [radial;in-track;cross-track];
    rVectInertDeputy = rVectInertChief + rVectChiefToDeputy;
    lvlhPosDeputy = computeLvlhPos(rVectInertChief, vVectInertChief, rVectChiefToDeputy);
    
    %%%%%Cross-track%%%%
    crosstrack = lvlhPosDeputy(3);
    
    %%%%%Radial%%%%%
    %get chief peri vector
    [sma, ecc, inc, raan, arg, truChief] = getKeplerFromState(rVectInertChief,vVectInertChief,gmuChief, true);
    [rVectInertChiefPeri,~]=getStatefromKepler(sma, ecc, inc, raan, arg, 0, gmuChief, true);
    
    %project deputy location onto chief orbit plane
    %  The projection of a point q = (x, y, z) onto a plane given by a point p = (a, b, c) and a normal n = (d, e, f) is
    %  q_proj = q - dot(q - p, n) * n
    %  This calculation assumes that n is a unit vector.
    %   http://stackoverflow.com/questions/8942950/how-do-i-find-the-orthogonal-projection-of-a-point-onto-a-plane
    
    hHat = normVector(cross(rVectInertChief, vVectInertChief));
    rVectInertDepOnChiefPlane = rVectInertDeputy - dotARH(rVectInertDeputy - [0;0;0], hHat)*hHat;
    
    truDeputyForRadial = dang(rVectInertChiefPeri,rVectInertDepOnChiefPlane);
    d = rVectInertChiefPeri(1)*rVectInertDepOnChiefPlane(2) - rVectInertChiefPeri(2)*rVectInertDepOnChiefPlane(1);
    
    if(d < 0)
        truDeputyForRadial = pi+(pi-truDeputyForRadial);
    end
    
    [rVectInertChiefForRadial,~]=getStatefromKepler(sma, ecc, inc, raan, arg, truDeputyForRadial, gmuChief, true);
    
    radial = norm(rVectInertDepOnChiefPlane) - norm(rVectInertChiefForRadial);
    
    %%%%%In-track%%%%
    n = 500;
    if(abs(truDeputyForRadial - truChief) > pi)
        if(truDeputyForRadial < truChief)
            truDeputyForRadial = truDeputyForRadial + 2*pi;
        elseif(truChief < truDeputyForRadial)
            truChief = truChief + 2*pi;
        end
    end
    chiefTruVect = linspace(truDeputyForRadial, truChief, n);
    
    zeroArr = zeros(size(chiefTruVect));
    
    v_sma = zeroArr + sma;
    v_ecc = zeroArr + ecc;
    v_inc = zeroArr + inc;
    v_raan = zeroArr + raan;
    v_arg = zeroArr + arg;
    v_gmu = zeroArr + gmuChief;
    
    [rVect,~]=vect_getStatefromKepler(v_sma, v_ecc, v_inc, v_raan, v_arg, chiefTruVect, v_gmu, true);
   
    intrack = sum(sqrt(sum(diff(rVect,1,2).^2,1)));
    
    if(lvlhPosDeputy(2) < 0)
        intrack = -intrack;
    end
    
    if(intrack>1800 || intrack < 374)
        a = 1;
    end
    
    lvlhCurviPosDeputy = [radial; intrack; crosstrack];
end

