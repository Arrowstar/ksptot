classdef LaunchVehicleViewProfileVectorData < matlab.mixin.SetGet
    %LaunchVehicleViewProfileVectorData Summary of this class goes here
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
        vector AbstractGeometricVector
        viewFrame AbstractReferenceFrame
    end
    
    methods
        function obj = LaunchVehicleViewProfileVectorData(vector, viewFrame)
            obj.vector = vector;
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
        
        function plotVectorAtTime(obj, time, hAx)   
            [origin, vect] = obj.getVectorAtTime(time);
            
            if(isempty(obj.markerPlot))
                for(i=1:size(vect,2))
                    hold(hAx,'on');       
                    obj.markerPlot(i) = quiver3(origin(1,i),origin(2,i),origin(3,i), vect(1,i),vect(2,i),vect(3,i), 'AutoScale','off', 'Color',obj.vector.lineColor.color, 'LineStyle',obj.vector.lineSpec.linespec);
                    hold(hAx,'off');
                end
            else
                for(i=1:size(vect,2))
                    obj.markerPlot(i).XData = origin(1,i);
                    obj.markerPlot(i).YData = origin(2,i);
                    obj.markerPlot(i).ZData = origin(3,i);

                    obj.markerPlot(i).UData = vect(1,i);
                    obj.markerPlot(i).VData = vect(2,i);
                    obj.markerPlot(i).WData = vect(3,i);
                end
            end
        end
    end
    
    methods(Access=private)
        function [origin, vect] = getVectorAtTime(obj, time)
            origin = [];
            vect = [];
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
                    vect(:,end+1) = obj.vector.getVectorAtTime(time, vehElemSet, obj.viewFrame);
                    
                    origin(:,end+1) = obj.vector.getOriginPointInViewFrame(time, vehElemSet, obj.viewFrame);
                end
            end
        end
    end
end