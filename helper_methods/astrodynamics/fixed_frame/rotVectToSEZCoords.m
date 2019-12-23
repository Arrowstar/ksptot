function vectorSez = rotVectToSEZCoords(rVectorECEF, vectorECEF)

    kHat = [0;0;1];
    zHat = normVector(rVectorECEF);
    eHat = normVector(cross(kHat, zHat));
    sHat = normVector(cross(eHat, zHat));
    
    rotMat = [sHat'; eHat'; zHat'];
    
    vectorSez = rotMat * vectorECEF;
end