function vector = rotSEZVectToECEFCoords(rVectorECEF, vectorSez)
    numVectors = size(rVectorECEF,2);
    
    kHat = repmat([0;0;1], 1, numVectors);
    zHat = vect_normVector(rVectorECEF);
    eHat = vect_normVector(cross(kHat, zHat));
    sHat = vect_normVector(cross(eHat, zHat));
    
    rotMat = [permute(sHat, [1, 3, 2]), ...
              permute(eHat, [1, 3, 2]), ...
              permute(zHat, [1, 3, 2])];
    
	vectorSez = reshape(vectorSez, [3, 1, numVectors]);
	vector = mtimesx(rotMat, vectorSez);
    vector = squeeze(vector);
end

%     kHat = [0;0;1];
%     zHat = normVector(rVectorECEF);
%     eHat = normVector(cross(kHat, zHat));
%     sHat = normVector(cross(eHat, zHat));
%     
%     rotMat = [sHat'; eHat'; zHat'];
%     
%     vector = rotMat' * vectorSez;