classdef LaunchVehicleViewProfileRefFrameData < matlab.mixin.SetGet
    %LaunchVehicleViewProfileUserRefFrameData Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %these are for vehicle trajectory data and not the point itself!
        timesArr(1,:) cell = {};
        xInterps(1,:) cell = {};
        yInterps(1,:) cell = {};
        zInterps(1,:) cell = {};
        vxInterps(1,:) cell = {};
        vyInterps(1,:) cell = {};
        vzInterps(1,:) cell = {};
        
        markerPlot = matlab.graphics.GraphicsPlaceholder.empty(1,0)
        refFrame AbstractGeometricRefFrame
        viewFrame AbstractReferenceFrame
    end
    
    methods
        function obj = LaunchVehicleViewProfileRefFrameData(refFrame, viewFrame)
            obj.refFrame = refFrame;
            obj.viewFrame = viewFrame;
        end
        
        function addData(obj, times, rVects, vVects)
            obj.timesArr(end+1) = {times};
            
            if(length(times) >= 3)
                method = 'pchip';
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
        
        function plotRefFrameAtTime(obj, time, hAx)   
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
                    
                    vehElemSet = CartesianElementSet(time, [x;y;z], [vx;vy;vz], obj.viewFrame);
                    [posOffsetOrigin, ~, ~, rotMatToInertial] = obj.refFrame.getRefFrameAtTime(time, vehElemSet, obj.viewFrame);
                    
                    scaleFactor = obj.refFrame.scaleFactor;
                    xAxis = [posOffsetOrigin(:), posOffsetOrigin(:) + rotMatToInertial(:,1)*scaleFactor];
                    yAxis = [posOffsetOrigin(:), posOffsetOrigin(:) + rotMatToInertial(:,2)*scaleFactor];
                    zAxis = [posOffsetOrigin(:), posOffsetOrigin(:) + rotMatToInertial(:,3)*scaleFactor];
                    
                    if(isempty(obj.markerPlot))
                        hold(hAx,'on');
                        obj.markerPlot(end+1) = plot3(hAx, xAxis(1,:), xAxis(2,:), xAxis(3,:), 'Color',obj.refFrame.xAxisColor.color, 'LineWidth',obj.refFrame.xAxisLineWidth, 'LineStyle',obj.refFrame.xAxisLineSpec.linespec);
                        obj.markerPlot(end+1) = plot3(hAx, yAxis(1,:), yAxis(2,:), yAxis(3,:), 'Color',obj.refFrame.yAxisColor.color, 'LineWidth',obj.refFrame.yAxisLineWidth, 'LineStyle',obj.refFrame.yAxisLineSpec.linespec);
                        obj.markerPlot(end+1) = plot3(hAx, zAxis(1,:), zAxis(2,:), zAxis(3,:), 'Color',obj.refFrame.zAxisColor.color, 'LineWidth',obj.refFrame.zAxisLineWidth, 'LineStyle',obj.refFrame.zAxisLineSpec.linespec);
                        hold(hAx,'off');
                    else
                        obj.markerPlot(1).XData = xAxis(1,:);
                        obj.markerPlot(1).YData = xAxis(2,:);
                        obj.markerPlot(1).ZData = xAxis(3,:);
                        
                        obj.markerPlot(2).XData = yAxis(1,:);
                        obj.markerPlot(2).YData = yAxis(2,:);
                        obj.markerPlot(2).ZData = yAxis(3,:);
                        
                        obj.markerPlot(3).XData = zAxis(1,:);
                        obj.markerPlot(3).YData = zAxis(2,:);
                        obj.markerPlot(3).ZData = zAxis(3,:);
                    end
                end
            end
        end
    end
end