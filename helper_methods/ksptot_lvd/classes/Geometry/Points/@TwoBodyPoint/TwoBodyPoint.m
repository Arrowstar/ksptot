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
        xInterps(1,:) cell = {};
        yInterps(1,:) cell = {};
        zInterps(1,:) cell = {};
        vxInterps(1,:) cell = {};
        vyInterps(1,:) cell = {};
        vzInterps(1,:) cell = {};
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
            newCartElems = repmat(CartesianElementSet.empty(0,1), [1, length(time)]);
            for(i=1:length(obj.timesArr))
                times = obj.timesArr{i};
                
                bool = time >= min(floor(times)) & time <= max(ceil(times));
                if(any(bool))  
                    boolTimes = time(bool);
                    
                    xInterp = obj.xInterps{i};
                    x = xInterp(boolTimes);
                    
                    yInterp = obj.yInterps{i};
                    y = yInterp(boolTimes);
                    
                    zInterp = obj.zInterps{i};
                    z = zInterp(boolTimes);
                    
                    vxInterp = obj.vxInterps{i};
                    vx = vxInterp(boolTimes);
                    
                    vyInterp = obj.vyInterps{i};
                    vy = vyInterp(boolTimes);
                    
                    vzInterp = obj.vzInterps{i};
                    vz = vzInterp(boolTimes);
                    
                    bodyInfo = obj.cbArr(i);
                    
                    rVect = [x(:)'; y(:)'; z(:)'];
                    vVect = [vx(:)'; vy(:)'; vz(:)'];
                    
                    subCartElems = CartesianElementSet(boolTimes, rVect, vVect, bodyInfo.getBodyCenteredInertialFrame());
%                     subCartElems = repmat(CartesianElementSet.getDefaultElements(), [1, length(boolTimes)]);
%                     for(j=1:length(boolTimes))
%                         subCartElems(j) = CartesianElementSet(boolTimes(j), [x(j);y(j);z(j)], [vx(j);vy(j);vz(j)], bodyInfo.getBodyCenteredInertialFrame());
%                     end
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
            
            for(i=1:length(chunkedStateLog))
                subStateLog = chunkedStateLog{i};
                
                times = subStateLog(:,1);
                rVects = subStateLog(:,2:4);
                vVects = subStateLog(:,5:7);
                bodyInfo = dummyLvdData.celBodyData.getBodyInfoById(subStateLog(1,8));
                
                obj.addDataToCache(times, rVects, vVects, bodyInfo);
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
        
        function useTf = openEditDialog(obj, hKsptotMainGUI)
%             useTf = lvd_EditTwoBodyPointGUI(obj, obj.lvdData, hKsptotMainGUI);
            
            output = AppDesignerGUIOutput({false});
            lvd_EditTwoBodyPointGUI_App(obj, obj.lvdData, hKsptotMainGUI, output);
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
            evt.integratorObj.getOptions().integratorStepSize = evtDur/1000;
            evt.propagatorObj = evt.twoBodyPropagator;
            
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
        
        function addDataToCache(obj, times, rVects, vVects, bodyInfo)
            obj.timesArr{end+1} = times;
            obj.cbArr(end+1) = bodyInfo;
            obj.rVectArr{end+1} = rVects;
            
            if(length(times) >= 3)
                method = 'spline';
            else
                method = 'linear';
            end
            
            obj.xInterps{end+1} = griddedInterpolant(times, rVects(:,1), method, 'nearest');
            obj.yInterps{end+1} = griddedInterpolant(times, rVects(:,2), method, 'nearest');
            obj.zInterps{end+1} = griddedInterpolant(times, rVects(:,3), method, 'nearest');
            obj.vxInterps{end+1} = griddedInterpolant(times, vVects(:,1), method, 'nearest');
            obj.vyInterps{end+1} = griddedInterpolant(times, vVects(:,2), method, 'nearest');
            obj.vzInterps{end+1} = griddedInterpolant(times, vVects(:,3), method, 'nearest');
        end
        
        function clearCache(obj)
            obj.timesArr = {};
            obj.xInterps = {};
            obj.yInterps = {};
            obj.zInterps = {};
            obj.vxInterps = {};
            obj.vyInterps = {};
            obj.vzInterps = {};
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
        end
    end
end