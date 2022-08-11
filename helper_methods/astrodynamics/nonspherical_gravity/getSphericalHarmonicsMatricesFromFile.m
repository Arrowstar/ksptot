function [C, S, maxOrderDeg] = getSphericalHarmonicsMatricesFromFile(gravityDataFile)
    arguments
        gravityDataFile(1,:) char
    end
    
    M = readmatrix(gravityDataFile);
    
    maxDeg = max(M(:,1));
    maxRows = maxDeg+1;
    
    maxOrder = max(M(:,2));
    maxCols = maxOrder+1;
    
    maxOrderDeg = min(maxRows, maxCols);

    C = zeros(maxRows, maxCols);
    ind = sub2ind([maxRows, maxCols],M(:,1)+1,M(:,2)+1);
    C(ind) = M(:,3);
    C = C(1:maxOrderDeg, 1:maxOrderDeg);

    S = zeros(maxRows, maxCols);
    ind = sub2ind([maxRows, maxCols],M(:,1)+1,M(:,2)+1);
    S(ind) = M(:,4);
    S = S(1:maxOrderDeg, 1:maxOrderDeg);
end