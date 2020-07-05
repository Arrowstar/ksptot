classdef LaunchVehicleViewProfileBodyData < matlab.mixin.SetGet
    %LaunchVehicleViewProfileBodyData Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        bodyInfo KSPTOT_BodyInfo
        
        timesArr(1,:) cell = {};
        xInterps(1,:) cell = {};
        yInterps(1,:) cell = {};
        zInterps(1,:) cell = {};
        
        markerPlot = matlab.graphics.GraphicsPlaceholder.empty(1,0)
    end
    
    methods
        function obj = LaunchVehicleViewProfileBodyData(bodyInfo)
            obj.bodyInfo = bodyInfo;
        end
        
        function addData(obj, times, rVects)
            obj.timesArr(end+1) = {times};
            
            obj.xInterps{end+1} = griddedInterpolant(times, rVects(1,:), 'spline', 'linear');
            obj.yInterps{end+1} = griddedInterpolant(times, rVects(2,:), 'spline', 'linear');
            obj.zInterps{end+1} = griddedInterpolant(times, rVects(3,:), 'spline', 'linear');
        end
        
        function plotBodyMarkerAtTime(obj, time, hAx)           
            for(i=1:length(obj.timesArr))
                times = obj.timesArr{i};
                
                if(time >= min(floor(times)) && time <= max(ceil(times)))
                    bColorRGB = obj.bodyInfo.getBodyRGB();
                    
                    xInterp = obj.xInterps{i};
                    x = xInterp(time);
                    
                    yInterp = obj.yInterps{i};
                    y = yInterp(time);
                    
                    zInterp = obj.zInterps{i};
                    z = zInterp(time);
                    
                    if(not(isempty(obj.markerPlot)) && isvalid(obj.markerPlot))
                        obj.markerPlot.XData = x;
                        obj.markerPlot.YData = y;
                        obj.markerPlot.ZData = z;
                    else
                        hold(hAx,'on');
                        obj.markerPlot = plot3(hAx, x,y,z, 'o', 'MarkerEdgeColor','k', 'MarkerFaceColor',bColorRGB);
                        hold(hAx,'off');
                    end
                    
                    break; %no need to plot more, if we hit the body at a certain time, then it'll only be at that position in time
                end
            end
        end
    end
end