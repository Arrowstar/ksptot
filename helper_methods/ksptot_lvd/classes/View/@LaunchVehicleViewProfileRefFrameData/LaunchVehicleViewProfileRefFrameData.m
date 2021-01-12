classdef LaunchVehicleViewProfileRefFrameData < matlab.mixin.SetGet
    %LaunchVehicleViewProfileUserRefFrameData Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        timesArr(1,:) cell = {};
        xInterps(1,:) cell = {};
        yInterps(1,:) cell = {};
        zInterps(1,:) cell = {};
        
        markerPlot = matlab.graphics.GraphicsPlaceholder.empty(1,0)
        refFrame AbstractGeometricRefFrame
        viewFrame AbstractReferenceFrame
    end
    
    methods
        function obj = LaunchVehicleViewProfileRefFrameData(refFrame, viewFrame)
            obj.refFrame = refFrame;
            obj.viewFrame = viewFrame;
        end
        
        function addData(obj, times, rVects)
            obj.timesArr(end+1) = {times};
            
            if(length(times) >= 3)
                method = 'spline';
            else
                method = 'linear';
            end
            
            obj.xInterps{end+1} = griddedInterpolant(times, rVects(:,1), method, 'linear');
            obj.yInterps{end+1} = griddedInterpolant(times, rVects(:,2), method, 'linear');
            obj.zInterps{end+1} = griddedInterpolant(times, rVects(:,3), method, 'linear');
        end
        
        function plotRefFrameAtTime(obj, time, hAx)   
            delete(obj.markerPlot);
            for(i=1:length(obj.timesArr))
                times = obj.timesArr{i};
                
                if(time >= min(floor(times)) && time <= max(ceil(times)))                    
                    xInterp = obj.xInterps{i};
                    x = xInterp(time);
                    
                    yInterp = obj.yInterps{i};
                    y = yInterp(time);
                    
                    zInterp = obj.zInterps{i};
                    z = zInterp(time);
                    
                    vehElemSet = CartesianElementSet(time, [x;y;z], [0;0;0], obj.viewFrame);
                    [posOffsetOrigin, ~, ~, rotMatToInertial] = obj.refFrame.getRefFrameAtTime(time, vehElemSet, obj.viewFrame);
                    
                    xAxis = [posOffsetOrigin(:), posOffsetOrigin(:) + rotMatToInertial(:,1)*100];
                    yAxis = [posOffsetOrigin(:), posOffsetOrigin(:) + rotMatToInertial(:,2)*100];
                    zAxis = [posOffsetOrigin(:), posOffsetOrigin(:) + rotMatToInertial(:,3)*100];
                    
                    hold(hAx,'on');
                    obj.markerPlot(end+1) = plot3(hAx, xAxis(1,:), xAxis(2,:), xAxis(3,:), 'r-');
                    obj.markerPlot(end+1) = plot3(hAx, yAxis(1,:), yAxis(2,:), yAxis(3,:), 'g-');
                    obj.markerPlot(end+1) = plot3(hAx, zAxis(1,:), zAxis(2,:), zAxis(3,:), 'b-');
                    hold(hAx,'off');
                end
            end
        end
    end
end