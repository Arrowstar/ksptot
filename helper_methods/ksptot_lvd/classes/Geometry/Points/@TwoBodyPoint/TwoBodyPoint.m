classdef TwoBodyPoint < AbstractGeometricPoint
    %FixedPointInFrame Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        elemSet AbstractElementSet = CartesianElementSet.getDefaultElements()
        
        name(1,:) char
        
        lvdData LvdData
        
        %marker
        markerColor(1,1) ColorSpecEnum = ColorSpecEnum.Red;
        markerShape(1,1) MarkerStyleEnum = MarkerStyleEnum.RightTriangle;
        
        %track line
        plotTrkLine(1,1) logical = true;
        trkLineColor(1,1) ColorSpecEnum = ColorSpecEnum.Black;
        trkLineSpec(1,1) LineSpecEnum = LineSpecEnum.DottedLine;
    end
    
    properties
        timesArr(1,:) cell = {};

        smaInterps(1,:) cell = {};
        eccInterps(1,:) cell = {};
        incInterps(1,:) cell = {};
        raanInterps(1,:) cell = {};
        argInterps(1,:) cell = {};
        meanInterps(1,:) cell = {};

        cbArr(1,:) KSPTOT_BodyInfo = KSPTOT_BodyInfo.empty(1,0);
        
        rVectArr(1,:) cell = {};
        
        markerPlot = matlab.graphics.GraphicsPlaceholder.empty(1,0);
    end
    
    methods
        function obj = TwoBodyPoint(elemSet, name, lvdData)
            obj.elemSet = elemSet;
            obj.name = name;
            obj.lvdData = lvdData;
        end
        
        function newCartElems = getPositionAtTime(obj, time, vehElemSet, inFrame)
            newCartElems = repmat(CartesianElementSet.empty(1,0), [1, length(time)]);
            for(i=1:length(obj.timesArr))
                times = obj.timesArr{i};
                
                bool = time >= min(floor(times)) & time <= max(ceil(times));
                if(any(bool))  
                    boolTimes = time(bool);
                    
                    smaInterp = obj.smaInterps{i};
                    sma = smaInterp(boolTimes);
                    
                    eccInterp = obj.eccInterps{i};
                    ecc = eccInterp(boolTimes);
                    
                    incInterp = obj.incInterps{i};
                    inc = incInterp(boolTimes);
                    
                    raanInterp = obj.raanInterps{i};
                    raan = raanInterp(boolTimes);
                    
                    argInterp = obj.argInterps{i};
                    arg = argInterp(boolTimes);
                    
                    meanInterp = obj.meanInterps{i};
                    mean = meanInterp(boolTimes);
                    
                    bodyInfo = obj.cbArr(i);
                    
                    tru = computeTrueAnomFromMean(mean, ecc);
                    subKepElems = KeplerianElementSet.empty(1,0);
                    for(j=1:length(sma))
                        subKepElems(j) = KeplerianElementSet(boolTimes(j), sma(j), ecc(j), inc(j), raan(j), arg(j), tru(j), bodyInfo.getBodyCenteredInertialFrame()); %#ok<AGROW> 
                    end
                    subCartElems = convertToCartesianElementSet(subKepElems);

                    newCartElems(bool) = subCartElems;
                end
            end
            
            if(not(isempty(newCartElems)))
                newCartElems = convertToFrame(newCartElems, inFrame);
            else
                [minTime, maxTime] = obj.getCacheMinMaxTimes();
                if(time < minTime)
                    diff = abs(minTime - time);
                    newMinTime = minTime - 10*diff;
                    obj.refeshTrajCache(newMinTime, maxTime);
                    
                elseif(time > maxTime)
                    diff = abs(time - maxTime);
                    newMaxTime = maxTime + 10*diff;
                    obj.refeshTrajCache(minTime, newMaxTime);
                end
                
                newCartElems = obj.getPositionAtTime(time, vehElemSet, inFrame);
            end
        end
        
        function refeshTrajCache(obj, minTime, maxTime)
            obj.clearCache();
            dummyLvdData = LvdData.getDefaultLvdData(obj.lvdData.celBodyData);
            
            if(isnan(minTime))
                minTime = 0;
            end

            if(minTime >= maxTime)
                maxTime = minTime + 1;
            end

            initState = dummyLvdData.initialState;
            
            ce = obj.elemSet.convertToCartesianElementSet();
            origBodyInfo = ce.frame.getOriginBody();
            ce = ce.convertToFrame(origBodyInfo.getBodyCenteredInertialFrame());
            
            initState.time = ce.time;
            initState.position = ce.rVect;
            initState.velocity = ce.vVect;
            initState.centralBody = origBodyInfo;
            initState.lvState.holdDownEnabled = false;
            
            evt = LaunchVehicleEvent(dummyLvdData.script);
            dummyLvdData.script.addEvent(evt);
            initState.event = evt;
            
            if(initState.time >= minTime && initState.time <= maxTime)
                newStateLogEntries = obj.doTwoBodyProp(initState, evt, minTime);
                
                initState = newStateLogEntries(end);
                newStateLogEntries = obj.doTwoBodyProp(initState, evt, maxTime);
                
            elseif(initState.time < minTime && initState.time < maxTime)
                newStateLogEntries = obj.doTwoBodyProp(initState, evt, maxTime);
                
            elseif(minTime < initState.time && maxTime < initState.time)
                newStateLogEntries = obj.doTwoBodyProp(initState, evt, minTime);
            end
            
            maStateLog = NaN(length(newStateLogEntries), 13);
            for(i=1:length(newStateLogEntries))
                 maStateLog(i,:) = newStateLogEntries(i).getMAFormattedStateLogMatrix(false);
            end
            maStateLog(:,13) = 1;
            
            [~,I] = sort(maStateLog(:,1),'ascend');
            maStateLog = maStateLog(I,:);
            
            chunkedStateLog = breakStateLogIntoSoIChunks(maStateLog);
            
            for(i=1:length(chunkedStateLog)) %#ok<*NO4LP> 
                subStateLog = chunkedStateLog{i};
                
                bodyInfo = dummyLvdData.celBodyData.getBodyInfoById(subStateLog(1,8));

                times = subStateLog(:,1);
                rVects = subStateLog(:,2:4)';
                vVects = subStateLog(:,5:7)';
                [smas, eccs, incs, raans, args, trus] = vect_getKeplerFromState(rVects, vVects, bodyInfo.gm);
                means = computeMeanFromTrueAnom(trus, eccs);

                raans = AngleZero2Pi(raans);
                args = AngleZero2Pi(args);

                %this is needed to prevent angle wrapping
                dTru = diff(trus);
                inds = find(dTru < 0);
                for(j=1:length(inds))
                    ind = inds(j);

                    trus(ind+1:end) = trus(ind+1:end) + 2*pi;
                end

                obj.addDataToCache(times, smas, eccs, incs, raans, args, means, bodyInfo);
            end
        end
               
        function name = getName(obj)
            name = obj.name;
        end
        
        function setName(obj, name)
            obj.name = name;
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('%s (Two Body Point)', obj.getName());
        end
        
        function useTf = openEditDialog(obj)           
            output = AppDesignerGUIOutput({false});
            lvd_EditTwoBodyPointGUI_App(obj, obj.lvdData, output);
            useTf = output.output{1};
        end
        
        function tf = isVehDependent(~)
            tf = true; %maybe need to set this to true
        end
        
        function tf = canBePlotted(obj)
            tf = true;
        end
        
        function bodyInfo = getOriginBody(obj)
            bodyInfo = obj.elemSet.frame.getOriginBody();
        end
        
        function tf = usesGroundObj(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricPoint(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricVector(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricCoordSys(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricRefFrame(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricAngle(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricPlane(~, ~)
            tf = false;
        end 
        
        function tf = isInUse(obj, lvdData)
            tf = lvdData.usesGeometricPoint(obj);
        end
    end
    
    methods(Access = private)
        function newStateLogEntries = doTwoBodyProp(obj, initState, evt, propToTime)
            evtDur = propToTime - initState.time;
            evt.termCond = EventDurationTermCondition(abs(evtDur));
            evt.integratorObj = evt.ode113Integrator;
            evt.propagatorObj = evt.twoBodyPropagator;
            
%             k = initState.getCartesianElementSetRepresentation().convertToKeplerianElementSet();
%             if(k.ecc < 1)
%                 period = k.getPeriod();
%                 stepSize = period/25;
%                 
%             else
%                 stepSize = evtDur/1000;
%             end
            stepSize = evtDur/1000;
            evt.integratorObj.getOptions().integratorStepSize = stepSize;
            evt.integratorObj.getOptions().maxNumFixedSteps = Inf;

            if(evtDur >= 0)
                evt.propDir = PropagationDirectionEnum.Forward;
            else
                evt.propDir = PropagationDirectionEnum.Backward;
            end
            
            oldMaxPropTime = obj.lvdData.settings.maxScriptPropTime;
            obj.lvdData.settings.maxScriptPropTime = Inf;
            
            oldMaxSimDur = obj.lvdData.settings.simMaxDur;
            obj.lvdData.settings.simMaxDur = abs(evtDur)*10;
            
            evt.initEvent(initState);
            newStateLogEntries = evt.executeEvent(initState, ...
                                                  obj.lvdData.script.simDriver, ...
                                                  tic(), ...
                                                  initState.time, ...
                                                  false, ...
                                                  LaunchVehicleNonSeqEvent.empty(1,0));
                                              
            obj.lvdData.settings.maxScriptPropTime = oldMaxPropTime;
            obj.lvdData.settings.simMaxDur = oldMaxSimDur;
        end
        
        function addDataToCache(obj, times, smas, eccs, incs, raans, args, means, bodyInfo)
            obj.timesArr{end+1} = times;
            obj.cbArr(end+1) = bodyInfo;
            
%             if(length(times) >= 3)
%                 method = 'linear';
%             else
%                 method = 'linear';
%             end
            method = 'linear';

            obj.smaInterps{end+1} = griddedInterpolant(times, smas, method, 'nearest');
            obj.eccInterps{end+1} = griddedInterpolant(times, eccs, method, 'nearest');
            obj.incInterps{end+1} = griddedInterpolant(times, incs, method, 'nearest');
            obj.raanInterps{end+1} = griddedInterpolant(times, raans, method, 'nearest');
            obj.argInterps{end+1} = griddedInterpolant(times, args, method, 'nearest');
            obj.meanInterps{end+1} = griddedInterpolant(times, means, method, 'nearest');
        end
        
        function clearCache(obj)
            obj.timesArr = {};

            obj.smaInterps = {};
            obj.eccInterps = {};
            obj.incInterps = {};
            obj.raanInterps = {};
            obj.argInterps = {};
            obj.meanInterps = {};

            obj.cbArr = KSPTOT_BodyInfo.empty(1,0);
        end
        
        function [minTime, maxTime] = getCacheMinMaxTimes(obj)
            minTime = Inf;
            maxTime = -Inf;
            for(i=1:length(obj.timesArr))
                times = obj.timesArr{i};
                if(min(times) < minTime)
                    minTime = min(times);
                end
                
                if(max(times) > maxTime)
                    maxTime = max(times);
                end
            end

            if(~isfinite(minTime))
                minTime = 0;
            end

            if(~isfinite(maxTime))
                maxTime = 20000;
            end
        end
    end
end