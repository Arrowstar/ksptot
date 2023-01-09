function [lvlhPosDeputy] = computeLvlhPos(rVectInertChief, vVectInertChief, rVectChiefToDeputy)
%computeLvlhPos See page 28 of SM-2013-NicholasAustin.pdf
%   Returns rectilinear LVLH coordinate system transform from inertial => [radial;in-track;crosstrack];

    rVectInertDeputy = rVectInertChief + rVectChiefToDeputy;

    eR_L = normVector(rVectInertChief);
    eN_L = normVector(crossARH(rVectInertChief, vVectInertChief));
    eT_L = normVector(crossARH(eN_L, eR_L));

    rCtoD = rVectChiefToDeputy;
    
    ECI2LvlhRotMat = horzcat(eR_L, eT_L, eN_L);
    
    lvlhPosDeputy = ECI2LvlhRotMat \ rCtoD;
end

