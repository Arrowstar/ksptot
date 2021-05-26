function rswVector = rotateVectorFromEciToRsw(eciVector, rVect, vVect)
    R = normVector(rVect);
    W = normVector(crossARH(rVect, vVect));
    S = normVector(crossARH(W,R));
    
    ECI2RSWRotMat = [R,S,W];
    
    rswVector = ECI2RSWRotMat \ eciVector;
end