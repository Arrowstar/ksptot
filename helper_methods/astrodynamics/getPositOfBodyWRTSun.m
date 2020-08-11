function [rVectB, vVectB] = getPositOfBodyWRTSun(time, bodyInfo, celBodyData)

    numTimes = length(time);
    loop = true;
    rVectB = zeros(3,numTimes);
    vVectB = zeros(3,numTimes);
    while(loop)
        try
            parentBodyInfo = bodyInfo.getParBodyInfo(celBodyData);
        catch 
            parentBodyInfo = getParentBodyInfo(bodyInfo, celBodyData);
        end
        
        if(isempty(parentBodyInfo))
            break;
        end
        
        parentGM = bodyInfo.getParentGmuFromCache();
        
        [rVect, vVect] = getStateAtTime(bodyInfo, time, parentGM); %getParentGM(bodyInfo, celBodyData)
        rVectB = rVectB + rVect;
        vVectB = vVectB + vVect;
        
        bodyInfo = parentBodyInfo;
    end
end