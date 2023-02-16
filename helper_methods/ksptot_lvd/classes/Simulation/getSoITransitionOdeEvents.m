function [value, isterminal, direction, causes] = getSoITransitionOdeEvents(ut, rVect, vVect, bodyInfo, celBodyData, createCausesArr)
        arguments
            ut(1,1) double
            rVect(3,1) double
            vVect(3,1) double
            bodyInfo(1,1) KSPTOT_BodyInfo
            celBodyData(1,1) CelestialBodyData
            createCausesArr(1,1) logical = true
        end

        persistent soiDownCauseEmpty emptyCauses

        if(isempty(soiDownCauseEmpty))
            soiDownCauseEmpty = SoITransitionDownIntTermCause();
        end

        if(isnumeric(emptyCauses) && isempty(emptyCauses))
            emptyCauses = AbstractIntegrationTerminationCause.empty(1,0);
        end

        value = [];
        isterminal = [];
        direction = [];
            
        %Max Radius (SoI Radius) Constraint (Leave SOI Upwards)
        parentBodyInfo = bodyInfo.getParBodyInfo(celBodyData);
        rSOI = bodyInfo.getCachedSoIRadius();
        radius = norm(rVect);

        causes = emptyCauses;

        if(rSOI < realmax)
            value(1) = rSOI - radius;
            isterminal(1) = 1;
            direction(1) = -1;
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
        
        bodyChainSc = bodyInfo.getOrbitElemsChain();

        children = bodyInfo.getChildrenBodyInfo(celBodyData);
        if(~isempty(children))
            if(createCausesArr)
                soiDownCauses = repmat(soiDownCauseEmpty, [1,length(children)]);
            end

            rSOIs = getCachedSoIRadius(children);
            [rApCBs, rPeCBs] = computeApogeePerigee([children.sma], [children.ecc]);
            downValue = NaN(1,length(children));
            downDirection = NaN(1,length(children));
            downIsterminal = NaN(1,length(children));
            for(i=1:length(children)) %#ok<*NO4LP>
                childBodyInfo = children(i);
                rSOI = rSOIs(i);
                rApCB = rApCBs(i);
                rPeCB = rPeCBs(i);
                
                if((rApSC < (rPeCB - rSOI)) || ...
                    rPeSC > (rApCB + rSOI))
                    val = realmax;
                    
                else
                    % dVect = getAbsPositBetweenSpacecraftAndBody(ut, rVect, bodyInfo, childBodyInfo, celBodyData);
                    dVect = getAbsPositBetweenSpacecraftAndBody_fast_mex(ut, rVect, bodyChainSc, childBodyInfo.getOrbitElemsChain(), vVect);
                    distToChild = norm(dVect);               

                    val = distToChild - rSOI;
                end

                downValue(i) = val; 
                downDirection(i) = -1; 
                downIsterminal(i) = 1; 
                if(createCausesArr)
                    soiDownCauses(i) = SoITransitionDownIntTermCause(bodyInfo, childBodyInfo, celBodyData);
                end
            end  

            value = horzcat(value, downValue);
            direction = horzcat(direction, downDirection);
            isterminal = horzcat(isterminal, downIsterminal);

            if(createCausesArr)
                causes = horzcat(causes, soiDownCauses);
            end
        end
end