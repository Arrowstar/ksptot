function vectorSez = rotVectToSEZCoords(rVectorECEF, vectorECEF)
    numVectors = size(rVectorECEF,2);
    
    kHat = repmat([0;0;1], 1, numVectors);
    zHat = vect_normVector(rVectorECEF);
    eHat = vect_normVector(cross(kHat, zHat));
    sHat = vect_normVector(cross(eHat, zHat));
    
    rotMat = [reshape(sHat, [1, 3, numVectors]); 
              reshape(eHat, [1, 3, numVectors]); 
              reshape(zHat, [1, 3, numVectors])];
    
    vectorECEF = reshape(vectorECEF, [3, 1, numVectors]);
    vectorSez = mtimesx(rotMat, vectorECEF);
    vectorSez = squeeze(vectorSez);
end
%     kHat = [0;0;1];
%     zHat = normVector(rVectorECEF);
%     eHat = normVector(cross(kHat, zHat));
%     sHat = normVector(cross(eHat, zHat));
%     
%     rotMat = [sHat'; eHat'; zHat'];
%     
%     vectorSez = rotMat * vectorECEF;

