classdef LaunchVehicleViewPosVelInterp < matlab.mixin.SetGet
    %LaunchVehicleViewPositionInterp Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %these are for vehicle trajectory data
        timesArr(1,:) cell = {};
        xInterps(1,:) cell = {};
        yInterps(1,:) cell = {};
        zInterps(1,:) cell = {};
        vxInterps(1,:) cell = {};
        vyInterps(1,:) cell = {};
        vzInterps(1,:) cell = {};
        
        viewFrame AbstractReferenceFrame
    end
    
    methods  
        function obj = LaunchVehicleViewPosVelInterp(viewFrame)
            obj.viewFrame = viewFrame;
        end
        
        function addData(obj, times, rVects, vVects)
            obj.timesArr{end+1} = times;
            
            if(length(times) >= 3)
                method = 'spline';
            else
                method = 'linear';
            end
            
            obj.xInterps{end+1} = griddedInterpolant(times, rVects(:,1), method, 'linear');
            obj.yInterps{end+1} = griddedInterpolant(times, rVects(:,2), method, 'linear');
            obj.zInterps{end+1} = griddedInterpolant(times, rVects(:,3), method, 'linear');
            obj.vxInterps{end+1} = griddedInterpolant(times, vVects(:,1), method, 'linear');
            obj.vyInterps{end+1} = griddedInterpolant(times, vVects(:,2), method, 'linear');
            obj.vzInterps{end+1} = griddedInterpolant(times, vVects(:,3), method, 'linear');
        end
    end
    
    methods
        function [rVect, vVect] = getPositionVelocityAtTime(obj, time)
            vehElemSet = repmat(CartesianElementSet.getDefaultElements(), [1, length(time)]);
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
                    vx = vxInterp(time);
                    
                    vyInterp = obj.vyInterps{i};
                    vy = vyInterp(time);
                    
                    vzInterp = obj.vzInterps{i};
                    vz = vzInterp(time);
                    
                    rVect = [x(:)'; y(:)'; z(:)'];
                    vVect = [vx(:)'; vy(:)'; vz(:)'];
                    
                    subCartElems = CartesianElementSet(boolTimes, rVect, vVect, obj.viewFrame);

                    vehElemSet(bool) = subCartElems;
                end
            end
            
            rVect = [vehElemSet.rVect]; 
            vVect = [vehElemSet.vVect];
        end
    end
end