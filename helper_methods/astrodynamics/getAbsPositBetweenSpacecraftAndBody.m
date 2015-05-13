function rVect = getAbsPositBetweenSpacecraftAndBody(time, rVectSC, bodySC, bodyOther, celBodyData)
%getAbsPositBetweenSpacecraftAndBody Summary of this function goes here
%   Detailed explanation goes here

    
    rVectBodySC = getPositOfBodyWRTSun(time, bodySC, celBodyData);
    rVectSCTot = bsxfun(@plus, rVectBodySC, rVectSC);
    
    rVectB = getPositOfBodyWRTSun(time, bodyOther, celBodyData);
    
    rVect = bsxfun(@minus, rVectB, rVectSCTot);
end

function rVectB = getPositOfBodyWRTSun(time, bodyInfo, celBodyData)

    numTimes = length(time);
    loop = true;
    rVectB = zeros(3,numTimes);
    while(loop)
        parentBodyInfo = getParentBodyInfo(bodyInfo, celBodyData);
        if(isempty(parentBodyInfo))
            break;
        end
        
        [rVect, ~] = getStateAtTime(bodyInfo, time, parentBodyInfo.gm);
        rVectB = rVectB + rVect;
        
        bodyInfo = parentBodyInfo;
    end
end