function eciVector = rotateVectorFromRsw2Eci(rswVector, rVect, vVect)
    R = normVector(rVect);
    W = normVector(crossARH(rVect, vVect));
    S = normVector(crossARH(W,R));
    
    RSW2ECIRotMat = [R,S,W]';
    
    eciVector = RSW2ECIRotMat \ rswVector;
end