function [rVectB, vVectB] = getPositOfBodyWRTSun(time, bodyInfo, celBodyData)  
    try
        if(bodyInfo.propTypeEnum == BodyPropagationTypeEnum.TwoBody || (numel(time) == 1 && time == bodyInfo.epoch))
            chain = bodyInfo.getOrbitElemsChain();
            [rVectB, vVectB] = getPositOfBodyWRTSun_alg_fast_mex(time, chain{:});
        elseif(bodyInfo.propTypeEnum == BodyPropagationTypeEnum.Numerical)
            parentBodyInfo = bodyInfo.getParBodyInfo(celBodyData);

            [rVect, vVect] = getStateAtTime(bodyInfo, time, []);
            cartElem = CartesianElementSet(time, rVect, vVect, parentBodyInfo.getBodyCenteredInertialFrame(), true);
            cartElem = convertToFrame(cartElem, celBodyData.getTopLevelBody().getBodyCenteredInertialFrame());

            rVectB = [cartElem.rVect];
            vVectB = [cartElem.vVect];

        else
            error('Unknown celestial body prop sim type.');
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
    
%     if(numel(time) > 1 && numel(time) == numel(bodyInfo))
%         [uniBodies,~,ic] = unique(bodyInfo,'stable');
%         
%         rVectB = NaN(3, numel(time));
%         vVectB = rVectB;
%         for(i=1:length(uniBodies))
%             subBodyInfo = uniBodies(i);
%             bool = i == ic;
%             subTimes = time(bool);
%             
%             [rVectB(:,bool), vVectB(:,bool)] = getPositOfBodyWRTSun(subTimes, subBodyInfo, celBodyData);
%         end
%     else
%         try %try new way
%             if(bodyInfo.propTypeEnum == BodyPropagationTypeEnum.TwoBody || (numel(time) == 1 && time == bodyInfo.epoch))
% %                 if(numel(time) == 1 && numel(bodyInfo.lastComputedTime) > 0 && bodyInfo.lastComputedTime == time)
% %                     rVectB = bodyInfo.lastComputedRVect;
% %                     vVectB = bodyInfo.lastComputedVVect;
% %                 else
% %                     chain = bodyInfo.getOrbitElemsChain();
% %                     [rVectB, vVectB] = getPositOfBodyWRTSun_alg(time, chain{:});
% % 
% %                     if(numel(time) == 1)
% %                         bodyInfo.lastComputedTime = time;
% %                         bodyInfo.lastComputedRVect = rVectB;
% %                         bodyInfo.lastComputedVVect = vVectB;
% %                     end
% %                 end
% 
%                 if(numel(time) == 1)
%                     bool = time == bodyInfo.lastComputedTime;
%                     
%                     if(any(bool))
%                         rVectVVectB = bodyInfo.lastComputedRVectVVect(:,bool);
%                         rVectB = rVectVVectB(1:3,1);
%                         vVectB = rVectVVectB(4:6,1);
%                         
%                     else
%                         chain = bodyInfo.getOrbitElemsChain();
%                         try
%                             [rVectB, vVectB] = getPositOfBodyWRTSun_alg_fast_mex(time, chain{:});
%                         catch ME %#ok<NASGU>
%                             [rVectB, vVectB] = getPositOfBodyWRTSun_alg(time, chain{:});
%                         end
% 
%                         bodyInfo.lastComputedTime = horzcat(bodyInfo.lastComputedTime, time);
%                         bodyInfo.lastComputedRVectVVect = horzcat(bodyInfo.lastComputedRVectVVect, [rVectB;vVectB]);
%                         
%                         [bodyInfo.lastComputedTime,ia,~] = unique(bodyInfo.lastComputedTime,'stable');
%                         bodyInfo.lastComputedRVectVVect = bodyInfo.lastComputedRVectVVect(:, ia);
%                     end
%                 else
%                     chain = bodyInfo.getOrbitElemsChain();
%                     try
%                         [rVectB, vVectB] = getPositOfBodyWRTSun_alg_fast_mex(time, chain{:});
%                     catch ME %#ok<NASGU>
%                         [rVectB, vVectB] = getPositOfBodyWRTSun_alg(time, chain{:});
%                     end
% 
%                     bodyInfo.lastComputedTime = horzcat(bodyInfo.lastComputedTime, time);
%                     bodyInfo.lastComputedRVectVVect = horzcat(bodyInfo.lastComputedRVectVVect, [rVectB;vVectB]);
%                     
%                     [bodyInfo.lastComputedTime,ia,~] = unique(bodyInfo.lastComputedTime,'stable');
%                     bodyInfo.lastComputedRVectVVect = bodyInfo.lastComputedRVectVVect(:, ia);
%                 end
% 
%             elseif(bodyInfo.propTypeEnum == BodyPropagationTypeEnum.Numerical)
%                 parentBodyInfo = bodyInfo.getParBodyInfo(celBodyData);
% 
%                 [rVect, vVect] = getStateAtTime(bodyInfo, time, []);
%                 cartElem = CartesianElementSet(time, rVect, vVect, parentBodyInfo.getBodyCenteredInertialFrame(), true);
%                 cartElem = convertToFrame(cartElem, celBodyData.getTopLevelBody().getBodyCenteredInertialFrame());
% 
%                 rVectB = [cartElem.rVect];
%                 vVectB = [cartElem.vVect];
% 
%             else
%                 error('Unknown celestial body prop sim type.');
%             end
%         catch ME %if bad then use old way
%             numTimes = length(time);
%             loop = true;
%             rVectB = zeros(3,numTimes);
%             vVectB = zeros(3,numTimes);
%             while(loop)
%                 try
%                     parentBodyInfo = bodyInfo.getParBodyInfo(celBodyData);
%                 catch 
%                     parentBodyInfo = getParentBodyInfo(bodyInfo, celBodyData);
%                 end
% 
%                 if(isempty(parentBodyInfo))
%                     break;
%                 end
% 
%                 try
%                     parentGM = bodyInfo.getParentGmuFromCache();
%                 catch
%                     parentGM = getParentGM(bodyInfo,celBodyData);
%                 end
% 
%                 [rVect, vVect] = getStateAtTime(bodyInfo, time, parentGM); %getParentGM(bodyInfo, celBodyData)
%                 rVectB = rVectB + rVect;
%                 vVectB = vVectB + vVect;
% 
%                 bodyInfo = parentBodyInfo;
%             end
%         end
%     end
end