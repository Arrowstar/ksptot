function [rVectB, vVectB] = getPositOfBodyWRTSun(time, bodyInfo, celBodyData)  
    try %try new way
%         fprintf('%s - %0.14f s\n', bodyInfo.name, time(1));
        if(numel(time) == 1 && bodyInfo.lastComputedTime == time)
            rVectB = bodyInfo.lastComputedRVect;
            vVectB = bodyInfo.lastComputedVVect;
        else
            chain = bodyInfo.getOrbitElemsChain();
            [rVectB, vVectB] = getPositOfBodyWRTSun_alg(time, chain{:});
            
            if(numel(time) == 1)
                bodyInfo.lastComputedTime = time;
                bodyInfo.lastComputedRVect = rVectB;
                bodyInfo.lastComputedVVect = vVectB;
            end
        end
    catch ME %if bad then use old way
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

            try
                parentGM = bodyInfo.getParentGmuFromCache();
            catch
                parentGM = getParentGM(bodyInfo,celBodyData);
            end

            [rVect, vVect] = getStateAtTime(bodyInfo, time, parentGM); %getParentGM(bodyInfo, celBodyData)
            rVectB = rVectB + rVect;
            vVectB = vVectB + vVect;

            bodyInfo = parentBodyInfo;
        end
    end
end