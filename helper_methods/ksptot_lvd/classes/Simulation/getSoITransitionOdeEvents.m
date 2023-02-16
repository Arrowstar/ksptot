function [value, isterminal, direction, causes] = getSoITransitionOdeEvents(ut, rVect, vVect, bodyInfo, celBodyData, createCausesArr)
        arguments
            ut(1,1) double
            rVect(3,1) double
            vVect(3,1) double
            bodyInfo(1,1) KSPTOT_BodyInfo
            celBodyData(1,1) CelestialBodyData
            createCausesArr(1,1) logical = true
        end

        persistent soiDownCauseEmpty

        if(isempty(soiDownCauseEmpty))
            soiDownCauseEmpty = SoITransitionDownIntTermCause();
        end

        value = [];
        isterminal = [];
        direction = [];
            
        %Max Radius (SoI Radius) Constraint (Leave SOI Upwards)
        parentBodyInfo = bodyInfo.getParBodyInfo(celBodyData);
        rSOI = bodyInfo.getCachedSoIRadius();
        radius = norm(rVect);

        causes = AbstractIntegrationTerminationCause.empty(1,0);

        if(rSOI < realmax)
            value(end+1) = rSOI - radius;
            isterminal(end+1) = 1;
            direction(end+1) = -1;
            if(createCausesArr)
                causes = SoITransitionUpIntTermCause(bodyInfo, parentBodyInfo, celBodyData);
            end
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
            if(createCausesArr)
                soiDownCauses = repmat(soiDownCauseEmpty, [1,length(children)]);
            end

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
                if(createCausesArr)
                    soiDownCauses(i) = SoITransitionDownIntTermCause(bodyInfo, childBodyInfo, celBodyData); %#ok<AGROW>
                end
            end    

            if(createCausesArr)
                causes = horzcat(causes, soiDownCauses);
            end
        end
end