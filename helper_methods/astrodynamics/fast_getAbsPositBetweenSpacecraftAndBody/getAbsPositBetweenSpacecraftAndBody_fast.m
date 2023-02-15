function [rVect,vVect] = getAbsPositBetweenSpacecraftAndBody_fast(time, rVectSC, bodyScChain, bodyOtherChain, vVectSC)
%getAbsPositBetweenSpacecraftAndBody_fast Summary of this function goes here
%   Detailed explanation goes here
%     arguments
%         time(1,1) double
%         rVectSC(3,1) double %km
%         bodyScChain(1,8) cell %sc body orbit elem chain
%         bodyOtherChain(:,8) cell %other body orbit elem chain
%         vVectSC(3,1) double = NaN(3,1);
%     end

    [rVectBodySC, vVectBodySC] = getPositOfBodyWRTSun_alg_fast(time, bodyScChain{:});
    rVectSCTot = bsxfun(@plus, rVectBodySC, rVectSC);

    numOtherBodies = numel(bodyOtherChain);

    rVectB = NaN(3,numOtherBodies);
    vVectB = NaN(3,numOtherBodies);
    for(i=1:numOtherBodies) %#ok<*NO4LP> 
        bChain = bodyOtherChain{i};

        [rVectB(:,i), vVectB(:,i)] = getPositOfBodyWRTSun_alg_fast(time, bChain{1}, bChain{2}, bChain{3}, bChain{4}, bChain{5}, bChain{6}, bChain{7}, bChain{8});
    end
    rVect = bsxfun(@minus, rVectB, rVectSCTot);

    if(not(all(isnan(vVectSC))))
        vVectSCTot = bsxfun(@plus, vVectBodySC, vVectSC);
        vVect = bsxfun(@minus, vVectB, vVectSCTot);
    else
        vVect = nan(size(rVect));
    end
end