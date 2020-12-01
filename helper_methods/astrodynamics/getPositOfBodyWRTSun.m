function [rVectB, vVectB] = getPositOfBodyWRTSun(time, bodyInfo, ~)   
    chain = bodyInfo.getOrbitElemsChain();
    [rVectB, vVectB] = getPositOfBodyWRTSun_alg(time, chain{:});
end

%     numTimes = length(time);
%     loop = true;
%     rVectB = zeros(3,numTimes);
%     vVectB = zeros(3,numTimes);
%     while(loop)
%         try
%             parentBodyInfo = bodyInfo.getParBodyInfo(celBodyData);
%         catch 
%             parentBodyInfo = getParentBodyInfo(bodyInfo, celBodyData);
%         end
%         
%         if(isempty(parentBodyInfo))
%             break;
%         end
%         
%         try
%             parentGM = bodyInfo.getParentGmuFromCache();
%         catch
%             parentGM = getParentGM(bodyInfo,celBodyData);
%         end
%         
%         [rVect, vVect] = getStateAtTime(bodyInfo, time, parentGM); %getParentGM(bodyInfo, celBodyData)
%         rVectB = rVectB + rVect;
%         vVectB = vVectB + vVect;
%         
%         bodyInfo = parentBodyInfo;
%     end
