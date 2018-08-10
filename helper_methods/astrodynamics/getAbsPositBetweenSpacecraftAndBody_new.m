function [rVect, vVect] = getAbsPositBetweenSpacecraftAndBody_new(time, rVectSC, bodySC, bodyOther, celBodyData, varargin)
%getAbsPositBetweenSpacecraftAndBody Summary of this function goes here
%   Detailed explanation goes here

    [rVectBodySC, vVectBodySC] = getPositOfBodyWRTSun(time, bodySC, celBodyData);
    rVectSCTot = bsxfun(@plus, rVectBodySC, rVectSC);
    
    [rVectB, vVectB] = getPositOfBodyWRTSun(time, bodyOther, celBodyData);
    
    rVect = bsxfun(@minus, rVectBodySC, rVectB);
    
    if(~isempty(varargin))
        vVectSC = varargin{1};
        vVectSCTot = bsxfun(@plus, vVectBodySC, vVectSC);
        
        vVect = bsxfun(@minus, vVectBodySC, vVectB);
    else
        vVect = zeros(size(rVect));
    end
end

function [rVectB, vVectB] = getPositOfBodyWRTSun(time, bodyInfo, celBodyData)

    numTimes = length(time);
    loop = true;
    rVectB = zeros(3,numTimes);
    vVectB = zeros(3,numTimes);
    while(loop)
        parentBodyInfo = getParentBodyInfo(bodyInfo, celBodyData);
        if(isempty(parentBodyInfo))
            break;
        end
        
        [rVect, vVect] = getStateAtTime(bodyInfo, time, getParentGM(bodyInfo, celBodyData));
        rVectB = rVectB + rVect;
        vVectB = vVectB + vVect;
        
        bodyInfo = parentBodyInfo;
    end
end