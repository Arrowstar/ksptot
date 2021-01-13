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
        
        markerPlot = matlab.graphics.GraphicsPlaceholder.empty(1,0);
    end
    
    methods
        function obj = TwoBodyPoint(elemSet, name, lvdData)
            obj.elemSet = elemSet;
            obj.name = name;
            obj.lvdData = lvdData;
        end
        
        function newCartElem = getPositionAtTime(obj, time, vehElemSet, inFrame)
            newCartElem = CartesianElementSet.empty(1,0);
            for(i=1:length(obj.timesArr))
                times = obj.timesArr{i};
                
                if(time >= min(floor(times)) && time <= max(ceil(times)))         
                    xInterp = obj.xInterps{i};
                    x = xInterp(time);
                    
                    yInterp = obj.yInterps{i};
                    y = yInterp(time);
                    
                    zInterp = obj.zInterps{i};
                    z = zInterp(time);
                    
                    vxInterp = obj.vxInterps{i};
                    vx = vxInterp(time);
                    
                    vyInterp = obj.vyInterps{i};
                    vy = vyInterp(time);
                    
                    vzInterp = obj.vzInterps{i};
                    vz = vzInterp(time);
                    
                    bodyInfo = obj.cbArr(i);
                    
                    newCartElem = CartesianElementSet(time, [x;y;z], [vx;vy;vz], bodyInfo.getBodyCenteredInertialFrame());
                    break;
                end
            end
            
            if(not(isempty(newCartElem)))
                newCartElem = newCartElem.convertToFrame(inFrame);
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
                
                newCartElem = obj.getPositionAtTime(time, vehElemSet, inFrame);
            end
        end
        
        function refeshTrajCache(obj, minTime, maxTime)
            obj.clearCache();
            
            initState = obj.lvdData.initialState;
            
            ce = obj.elemSet.convertToCartesianElementSet();
            origBodyInfo = ce.frame.getOriginBody();
            ce = ce.convertToFrame(origBodyInfo.getBodyCenteredInertialFrame());
            
            initState.time = ce.time;
            initState.position = ce.rVect;
            initState.velocity = ce.vVect;
            initState.centralBody = origBodyInfo;
            
            evt = LaunchVehicleEvent(obj.lvdData.script);
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
                bodyInfo = obj.lvdData.celBodyData.getBodyInfoById(subStateLog(1,8));
                
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
            useTf = lvd_EditTwoBodyPointGUI(obj, obj.lvdData, hKsptotMainGUI);
        end
        
        function tf = isVehDependent(~)
            tf = false; %maybe need to set this to true
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
        
        function tf = isInUse(obj, lvdData)
            tf = lvdData.geometry.usesGeometricPoint(obj);
        end
    end
    
    methods(Access = private)
        function newStateLogEntries = doTwoBodyProp(obj, initState, evt, propToTime)
            evtDur = propToTime - initState.time;
            evt.termCond = EventDurationTermCondition(abs(evtDur));
            evt.integratorObj = evt.ode45Integrator;
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
            obj.timesArr(end+1) = {times};
            obj.cbArr(end+1) = bodyInfo;
            
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