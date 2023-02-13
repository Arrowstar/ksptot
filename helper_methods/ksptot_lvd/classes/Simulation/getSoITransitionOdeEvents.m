function [value, isterminal, direction, causes] = getSoITransitionOdeEvents(ut, rVect, vVect, bodyInfo, celBodyData)
        value = [];
        isterminal = [];
        direction = [];
%         causes = AbstractIntegrationTerminationCause.empty(0,1);
            
        %Max Radius (SoI Radius) Constraint (Leave SOI Upwards)
        parentBodyInfo = bodyInfo.getParBodyInfo(celBodyData);
%         rSOI = getSOIRadius(bodyInfo, parentBodyInfo);
        rSOI = bodyInfo.getCachedSoIRadius();
        radius = norm(rVect);

%         if(isempty(parentBodyInfo))
%             parentBodyInfo = KSPTOT_BodyInfo.empty(0,1);
%         end

        if(rSOI < realmax)
            value(end+1) = rSOI - radius;
            isterminal(end+1) = 1;
            direction(end+1) = -1;
            causes = SoITransitionUpIntTermCause(bodyInfo, parentBodyInfo, celBodyData);
        else
            causes = AbstractIntegrationTerminationCause.empty(1,0);
        end

        %Leave SoI Downwards
%         [sma, ecc, ~, ~, ~, ~] = getKeplerFromState(rVect, vVect, bodyInfo.gm, false);
        [sma, ecc, ~, ~, ~, ~] = getKeplerFromState_Alg(rVect, vVect, bodyInfo.gm);
        [rApSC, rPeSC] = computeApogeePerigee(sma, ecc);
        
        if(ecc >= 1)
            rApSC = Inf;
        end
        
        children = bodyInfo.getChildrenBodyInfo(celBodyData);
        if(~isempty(children))
%             soiDownCauses(length(children)) = SoITransitionDownIntTermCause(bodyInfo, children(end), celBodyData);
            for(i=length(children):-1:1) %#ok<*NO4LP>
                childBodyInfo = children(i);
                rSOI = childBodyInfo.getCachedSoIRadius();
                [rApCB, rPeCB] = computeApogeePerigee(childBodyInfo.sma, childBodyInfo.ecc);
                
                if((rApSC < (rPeCB - rSOI)) || ...
                    rPeSC > (rApCB + rSOI))
                    val = realmax;
                    
                else
%                     [cRVect, ~] = getStateAtTime(childBodyInfo, ut, bodyInfo.gm);
%                     distToChild = norm(rVect - cRVect);
                    dVect = getAbsPositBetweenSpacecraftAndBody(ut, rVect, bodyInfo, childBodyInfo, celBodyData);
                    distToChild = norm(dVect);               

                    val = distToChild - rSOI;
                end

                value(end+1) = val; %#ok<AGROW>
                direction(end+1) = -1; %#ok<AGROW>
                isterminal(end+1) = 1; %#ok<AGROW>
                soiDownCauses(i) = SoITransitionDownIntTermCause(bodyInfo, childBodyInfo, celBodyData); %#ok<AGROW>
            end    
%             causes = [causes, soiDownCauses];
            causes = horzcat(causes, soiDownCauses);
        end
end