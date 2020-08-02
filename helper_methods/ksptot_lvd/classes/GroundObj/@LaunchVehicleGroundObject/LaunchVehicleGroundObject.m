classdef LaunchVehicleGroundObject < matlab.mixin.SetGet
    %LaunchVehicleGroundObject Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name(1,:) char = 'Untitled Ground Object';
        desc(1,1) string = "";
        
        initialTime(1,1) double = 0;
        wayPts(1,:) LaunchVehicleGroundObjectWayPt
        
        extrapolateTimes(1,1) logical = true;
        loopWayPts(1,1) logical = true;
        
        %marker
        markerColor(1,1) ColorSpecEnum = ColorSpecEnum.Red;
        markerShape(1,1) MarkerStyleEnum = MarkerStyleEnum.UpTriangle;
        
        %ground track line
        grdTrkLineColor(1,1) ColorSpecEnum = ColorSpecEnum.Black;
        grdTrkLineSpec(1,1) LineSpecEnum = LineSpecEnum.DashedLine;
        
        groundObjs LaunchVehicleGroundObjectSet
    end
    
    properties(Dependent)
        centralBodyInfo
        lvdData
    end
    
    methods
        function obj = LaunchVehicleGroundObject(name, desc, initialTime, wayPts)
            obj.name = name;
            obj.desc = desc;
            obj.initialTime = initialTime;
            obj.wayPts = wayPts;
        end
        
        function bodyInfo = get.centralBodyInfo(obj)
            bodyInfo = obj.wayPts(1).elemSet.frame.getOriginBody();
        end
        
        function lvdData = get.lvdData(obj)
            lvdData = obj.groundObjs.lvdData;
        end
        
        function set.centralBodyInfo(obj, newBodyInfo)
            for(i=1:length(obj.wayPts))
                obj.wayPts(i).elemSet.frame = newBodyInfo.getBodyFixedFrame();
            end
        end
        
        function addWaypoint(obj, wayPt)
            obj.wayPts(end+1) = wayPt;
        end
        
        function removeWaypoint(obj, wayPt)
            obj.wayPts([obj.wayPts] == wayPt) = [];
        end
        
        function moveWayPtAtIndexDown(obj, ind)
            if(ind < length(obj.loopWayPts))
                obj.loopWayPts([ind+1,ind]) = obj.loopWayPts([ind,ind+1]);
            end
        end
        
        function moveWayPtAtIndexUp(obj, ind)
            if(ind > 1)
                obj.loopWayPts([ind,ind-1]) = obj.loopWayPts([ind-1,ind]);
            end
        end
        
        function wayPt = getWayPointAtInd(obj, ind)
            wayPt = obj.wayPts(ind);
        end
        
        function numWayPts = getNumWayPts(obj)
            numWayPts = length(obj.wayPts);
        end
        
        function listBoxStr = getWayListboxStr(obj)
            listBoxStr = {};
            
            for(i=1:length(obj.wayPts))
                listBoxStr{end+1} = sprintf('%02u - %s', i, obj.wayPts(i).getDisplayStr()); %#ok<AGROW>
            end
        end
        
        function wayPt2 = getNextWaypt(obj, wayPt)
            idx = find(wayPt == obj.wayPts,1,'first');
            
            if(idx == length(obj.wayPts))
                if(obj.loopWayPts)
                    wayPt2 = obj.wayPts(1);
                else
                    wayPt2 = LaunchVehicleGroundObjectWayPt.empty(1,0);
                end
            else
                wayPt2 = obj.wayPts(idx+1);
            end  
        end
        
        function dist = getDistanceBetweenWayPts(obj, wayPt1, wayPt2)
            lat1 = wayPt1.getLatitude();
            long1 = wayPt1.getLongitude();

            lat2 = wayPt2.getLatitude();
            long2 = wayPt2.getLongitude();
            
            bodyRadius = obj.centralBodyInfo.radius;
            arclength = distance(lat1,long1, lat2,long2, 'radians');
            dist = arclength * bodyRadius;
        end
        
        function elemSet = getStateAtTime(obj, time)
            if(length(obj.wayPts) == 1)
                elemSet = obj.wayPts(1).getElemSet().copyWithoutOptVar();
                elemSet.time = time;
                
            elseif(length(obj.wayPts) > 1)
                if(obj.extrapolateTimes && obj.loopWayPts)
                    [f, wayPt1, wayPt2, segTimes, adjustedTime] = obj.getFractionAndWaypointsIfLooping(time);
                    
                elseif(obj.extrapolateTimes && not(obj.loopWayPts))
                    [f, wayPt1, wayPt2, segTimes, adjustedTime] = obj.getFractionAndWaypointsIfNotLooping(time);

                elseif(not(obj.extrapolateTimes) && obj.loopWayPts)
                    wptTimeOffsets = [obj.wayPts.getTimesToNextWaypt()]; %#ok<NBRAK>
                    totalWayPtDuration = sum(wptTimeOffsets);
                    timeFrac = (time - obj.initialTime)/totalWayPtDuration;
                    
                    if(timeFrac < 0 || timeFrac > 1.0)
                        elemSet = GeographicElementSet.empty(1,0);
                        
                        return;
                    end
                    
                    [f, wayPt1, wayPt2, segTimes, adjustedTime] = obj.getFractionAndWaypointIfLooping(time);
                    
                elseif(not(obj.extrapolateTimes) && not(obj.loopWayPts))
                    wptTimeOffsets = [obj.wayPts.getTimesToNextWaypt()]; %#ok<NBRAK>
                    wptTimeOffsets = wptTimeOffsets(1:end-1);
                    wptTimeOffsets = [wptTimeOffsets, wptTimeOffsets(end:-1:1)];
                    
                    totalWayPtDuration = sum(wptTimeOffsets);
                    
                    timeFrac = (time - obj.initialTime)/totalWayPtDuration;
                    
                    if(timeFrac < 0 || timeFrac > 1.0)
                        elemSet = GeographicElementSet.empty(1,0);
                        
                        return;
                    end
                    
                    [f, wayPt1, wayPt2, segTimes, adjustedTime] = obj.getFractionAndWaypointsIfNotLooping(time);
                end

                bodyRadius = obj.centralBodyInfo.radius;
                [lati,longi] = getIntermediatePt(wayPt1.getLatitude(), wayPt1.getLongitude(), wayPt2.getLatitude(), wayPt2.getLongitude(), f, bodyRadius);

                alts = [wayPt1.getAltitude(); wayPt2.getAltitude()];
                newAlt = interp1qr(segTimes(:),alts, adjustedTime);

                frame = obj.centralBodyInfo.getBodyFixedFrame();
                elemSet = GeographicElementSet(time, lati, longi, newAlt, 0,0,0, frame);

            else
                error('Need at least one waypoint!');
                
            end
        end
        
        function tf = isInUse(obj)
            
        end
    end
    
    methods(Access=private)
        function [f, wayPt1, wayPt2, segTimes, adjustedTime] = getFractionAndWaypointsIfLooping(obj, time)
            wptTimeOffsets = [obj.wayPts.getTimesToNextWaypt()]; %#ok<NBRAK>
            totalWayPtDuration = sum(wptTimeOffsets);
            
            cumSumOffsets = cumsum(wptTimeOffsets);
            wayPtTimes = [0 cumSumOffsets(1:end-1);
                          cumSumOffsets];
%             
%             wayPtTimes = [cumsum(wptTimeOffsets) - wptTimeOffsets(1);
%                           cumsum(wptTimeOffsets)];

            adjustedTime = mod((time - obj.initialTime), totalWayPtDuration);
            idx = find(adjustedTime >= wayPtTimes(1,:) & adjustedTime <= wayPtTimes(2,:), 1, 'first');
            segTimes = wayPtTimes(:,idx);

            f = 1 - (segTimes(2) - adjustedTime)/diff(segTimes);

            wayPt1 = obj.wayPts(idx);

            if(idx == length(obj.wayPts))
                wayPt2 = obj.wayPts(1);
            else
                wayPt2 = obj.wayPts(idx+1);
            end    
        end
        
        function [f, wayPt1, wayPt2, segTimes, adjustedTime] = getFractionAndWaypointsIfNotLooping(obj, time)
            wptTimeOffsets = [obj.wayPts.getTimesToNextWaypt()]; %#ok<NBRAK>
            wptTimeOffsets = wptTimeOffsets(1:end-1);
            wptTimeOffsets = [wptTimeOffsets, wptTimeOffsets(end:-1:1)];

            cumSumOffsets = cumsum(wptTimeOffsets);
            wayPtTimes = [0 cumSumOffsets(1:end-1);
                          cumSumOffsets];
            
%             wayPtTimes = [cumsum(wptTimeOffsets) - wptTimeOffsets(1);
%                           cumsum(wptTimeOffsets)];

            wayPtInds = [1:1:length(obj.wayPts), length(obj.wayPts)-1:-1:2;
                         2:1:length(obj.wayPts), length(obj.wayPts)-1:-1:1];

            totalWayPtDuration = sum(wptTimeOffsets);

            adjustedTime = mod((time - obj.initialTime), totalWayPtDuration);
            idx = find(adjustedTime >= wayPtTimes(1,:) & adjustedTime <= wayPtTimes(2,:), 1, 'first');
            segTimes = wayPtTimes(:,idx);
            segWpInds = wayPtInds(:,idx);

            f = 1 - (segTimes(2) - adjustedTime)/diff(segTimes);

            wayPt1 = obj.wayPts(segWpInds(1));
            wayPt2 = obj.wayPts(segWpInds(2));
        end
    end
    
    methods(Static)        
        function grdObj = getDefaultObj(celBodyData)
            bodyInfo = LvdData.getDefaultInitialBodyInfo(celBodyData);
            bfFrame = bodyInfo.getBodyFixedFrame();
            
            initialTime = 0;
            
            wayPts = LaunchVehicleGroundObjectWayPt.empty(1,0);
            
            durToNextWayPt1 = 1000;
            elemSet = GeographicElementSet(initialTime + durToNextWayPt1, 0, 0, 0, 0, 0, 0, bfFrame);
            wayPts(1) = LaunchVehicleGroundObjectWayPt(elemSet, durToNextWayPt1);
            
            grdObj = LaunchVehicleGroundObject('Default Ground Object', "", 0, wayPts);
        end
    end
end

function [lati,longi] = getIntermediatePt(lat1, long1, lat2, long2, f, bodyRadius)
    d = distance(lat1,long1, lat2,long2, 'radians');
    delta = d/bodyRadius;
    
    a = sin((1-f)*delta) / sin(delta);
    b = sin(f*delta) / sin(delta);
    
    x = a * cos(lat1) * cos(long1) + b * cos(lat2) * cos(long2);
    y = a * cos(lat1) * sin(long1) + b * cos(lat2) * sin(long2);
    z = a * sin(lat1) + b * sin(lat2);
    
    lati = atan2(z, sqrt(x^2 + y^2));
    longi = atan2(y, x);
end