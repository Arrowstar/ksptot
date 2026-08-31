function [value, isterminal, direction, causes] = getSoITransitionOdeEvents(ut, rVect, vVect, bodyInfo, celBodyData, createCausesArr)
        arguments
            ut(1,1) double
            rVect(3,1) double
            vVect(3,1) double
            bodyInfo(1,1) KSPTOT_BodyInfo
            celBodyData(1,1) CelestialBodyData
            createCausesArr(1,1) logical = true
        end

        persistent soiDownCauseEmpty emptyCauses cachedSoiBody cachedSoiCelBodyData cachedUpCause cachedDownCauses

        if(isempty(soiDownCauseEmpty))
            soiDownCauseEmpty = SoITransitionDownIntTermCause();
        end

        if(isnumeric(emptyCauses) && isempty(emptyCauses))
            emptyCauses = AbstractIntegrationTerminationCause.empty(1,0);
        end

        % Invalidate cause-object caches when the central body changes (e.g. after a SoI
        % transition restart).  Key on OBJECT IDENTITY, not bodyInfo.id: ids are only
        % unique within one body database, and every mission file carries its own
        % serialized celBodyData, so two missions opened in the same session hand this
        % function distinct KSPTOT_BodyInfo objects sharing an id while differing in gm,
        % SoI radius and orbit elements.  An id-keyed cache hits straight across that
        % boundary, and the cause objects it hands back are not inert metadata:
        % SoITransitionUpIntTermCause.getRestartInitialState converts the state using its
        % stored celBodyData and sets centralBody to its stored toBody, so a stale cause
        % restarts integration about the PREVIOUS mission's celestial body.
        if(isempty(cachedSoiBody) || cachedSoiBody ~= bodyInfo || cachedSoiCelBodyData ~= celBodyData)
            cachedSoiBody        = bodyInfo;
            cachedSoiCelBodyData = celBodyData;
            cachedUpCause        = [];
            cachedDownCauses     = [];
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
                if(isempty(cachedUpCause))
                    cachedUpCause = SoITransitionUpIntTermCause(bodyInfo, parentBodyInfo, celBodyData);
                end
                causes = cachedUpCause;
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
            % Build down-cause objects once per central body; reuse on subsequent calls
            if(createCausesArr && isempty(cachedDownCauses))
                cachedDownCauses = repmat(soiDownCauseEmpty, [1,length(children)]);
                for(k=1:length(children)) %#ok<*NO4LP>
                    cachedDownCauses(k) = SoITransitionDownIntTermCause(bodyInfo, children(k), celBodyData);
                end
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
            end

            value = horzcat(value, downValue);
            direction = horzcat(direction, downDirection);
            isterminal = horzcat(isterminal, downIsterminal);

            if(createCausesArr)
                causes = horzcat(causes, cachedDownCauses);
            end
        end
end