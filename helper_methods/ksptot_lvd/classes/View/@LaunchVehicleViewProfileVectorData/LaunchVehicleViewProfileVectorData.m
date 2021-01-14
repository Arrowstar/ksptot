classdef LaunchVehicleViewProfileVectorData < matlab.mixin.SetGet
    %LaunchVehicleViewProfileVectorData Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %these are for vehicle trajectory data and not the point itself!
        timesArr(1,:) cell = {};
        xInterps(1,:) cell = {};
        yInterps(1,:) cell = {};
        zInterps(1,:) cell = {};
        
        markerPlot = matlab.graphics.GraphicsPlaceholder.empty(1,0)
        vector AbstractGeometricVector
        viewFrame AbstractReferenceFrame
    end
    
    methods
        function obj = LaunchVehicleViewProfileVectorData(vector, viewFrame)
            obj.vector = vector;
            obj.viewFrame = viewFrame;
        end
        
        function addData(obj, times, rVects)
            obj.timesArr{end+1} = times;
            
            if(length(times) >= 3)
                method = 'spline';
            else
                method = 'linear';
            end
            
            obj.xInterps{end+1} = griddedInterpolant(times, rVects(:,1), method, 'linear');
            obj.yInterps{end+1} = griddedInterpolant(times, rVects(:,2), method, 'linear');
            obj.zInterps{end+1} = griddedInterpolant(times, rVects(:,3), method, 'linear');
        end
        
        function plotVectorAtTime(obj, time, hAx)   
            [origin, vect] = obj.getVectorAtTime(time);
            vect = 1 * vect;
            
            if(isempty(obj.markerPlot))
                hold(hAx,'on');       
                obj.markerPlot = quiver3(origin(1),origin(2),origin(3), vect(1),vect(2),vect(3), 'AutoScale','off', 'Color',obj.vector.lineColor.color, 'LineStyle',obj.vector.lineSpec.linespec);
                hold(hAx,'off');
            else
                obj.markerPlot.XData = origin(1);
                obj.markerPlot.YData = origin(2);
                obj.markerPlot.ZData = origin(3);
                
                obj.markerPlot.UData = vect(1);
                obj.markerPlot.VData = vect(2);
                obj.markerPlot.WData = vect(3);
            end
        end
    end
    
    methods(Access=private)
        function [origin, vect] = getVectorAtTime(obj, time)
            origin = NaN(3,1);
            vect = NaN(3,1);
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
                    vect = obj.vector.getVectorAtTime(time, vehElemSet, obj.viewFrame);
                    
                    origin = obj.vector.getOriginPointInViewFrame(time, vehElemSet, obj.viewFrame);
                    
                    break;
                end
            end
        end
    end
end