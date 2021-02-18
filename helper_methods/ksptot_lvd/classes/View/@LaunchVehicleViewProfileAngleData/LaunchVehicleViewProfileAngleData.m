classdef LaunchVehicleViewProfileAngleData < matlab.mixin.SetGet
    %LaunchVehicleViewProfileAngleData Summary of this class goes here
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
        angle AbstractGeometricAngle
        viewFrame AbstractReferenceFrame
    end
    
    methods
        function obj = LaunchVehicleViewProfileAngleData(angle, viewFrame)
            obj.angle = angle;
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
        
        function plotAngleAtTime(obj, time, hAx)
            [startPts, angleMags, anglePlaneNorms] = obj.getAngleAtTime(time);
            
            numPtsPerAngle = 100;
            if(isempty(obj.markerPlot))
                hold(hAx,'on'); 
                for(i=1:size(angleMags,2))
                    angleMag = angleMags(i);
                    startPt = startPts(:,i);
                    anglePlaneNorm = anglePlaneNorms(:,i);
                    
                    anglePts = obj.getAnglePts(angleMag, startPt, anglePlaneNorm, numPtsPerAngle);
                    
                    obj.markerPlot(i) = plot3(anglePts(1,:), anglePts(2,:), anglePts(3,:), 'Color',obj.angle.lineColor.color, 'LineStyle', obj.angle.lineSpec.linespec);
                end
                hold(hAx,'off');
            else
                for(i=1:length(obj.markerPlot))
                    angleMag = abs(angleMags(i));
                    startPt = startPts(:,i);
                    anglePlaneNorm = anglePlaneNorms(:,i);
                    
                    anglePts = obj.getAnglePts(angleMag, startPt, anglePlaneNorm, numPtsPerAngle);
                    
                    obj.markerPlot(i).XData = anglePts(1,:);
                    obj.markerPlot(i).YData = anglePts(2,:);
                    obj.markerPlot(i).ZData = anglePts(3,:);
                end
            end
        end
    end
    
    methods(Access=private)
        function [startPt, angleMag, anglePlaneNorm] = getAngleAtTime(obj, time)
            startPt = [];
            angleMag = [];
            anglePlaneNorm = [];
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
                    
                    angleMag(end+1) = obj.angle.getAngleAtTime(time, vehElemSet, obj.viewFrame); %#ok<AGROW>
                    startPt(:,end+1) = obj.angle.getAngleStartPointAtTime(time, vehElemSet, obj.viewFrame); %#ok<AGROW>
                    anglePlaneNorm(:,end+1) = obj.angle.getAnglePlaneNormalAtTime(time, vehElemSet, obj.viewFrame); %#ok<AGROW>
                end
            end
        end
        
        function anglePts = getAnglePts(~, angleMag, startPt, anglePlaneNorm, numPtsPerAngle)
            r = [anglePlaneNorm(:)', 0];
            r = repmat(r,numPtsPerAngle,1);

            thetas = linspace(0, angleMag, numPtsPerAngle);
            r(:,4) = thetas(:);
            M = axang2rotmARH(r);

            startPt = repmat(startPt,1,1,numPtsPerAngle);
            anglePts = squeeze(mtimesx(M,startPt));
        end
    end
end