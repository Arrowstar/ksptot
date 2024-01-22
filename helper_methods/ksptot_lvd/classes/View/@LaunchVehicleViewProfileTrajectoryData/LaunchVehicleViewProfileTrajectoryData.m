classdef LaunchVehicleViewProfileTrajectoryData < matlab.mixin.SetGet
    %LaunchVehicleViewProfileTrajectoryData Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        timesArr(1,:) cell = {};
        xInterps(1,:) cell = {};
        yInterps(1,:) cell = {};
        zInterps(1,:) cell = {};
        
        evtColors(1,:) ColorSpecEnum = ColorSpecEnum.empty(1,0);
        markerPlot = matlab.graphics.GraphicsPlaceholder.empty(1,0)
    end
    
    methods
        function obj = LaunchVehicleViewProfileTrajectoryData()

        end
        
        function addData(obj, times, rVects, evtColor)
            if(length(unique(times)) == 1)
                times = [times, times+10*eps(times(1))];
                rVects = [rVects; rVects];
            end

            obj.timesArr(end+1) = {times};
            
            if(length(times) >= 3)
                method = 'pchip';
            else
                method = 'linear';
            end
           
            try
                obj.xInterps{end+1} = griddedInterpolant(times, rVects(:,1), method, 'linear');
                obj.yInterps{end+1} = griddedInterpolant(times, rVects(:,2), method, 'linear');
                obj.zInterps{end+1} = griddedInterpolant(times, rVects(:,3), method, 'linear');
                obj.evtColors(end+1) = evtColor;
            catch ME
                warning(ME.message);
            end
        end
        
        function plotBodyMarkerAtTime(obj, time, hAx)   
            delete(obj.markerPlot);
            for(i=1:length(obj.timesArr)) %#ok<*NO4LP> 
                times = obj.timesArr{i};
                
                if(not(isempty(times)))
                    if(time >= min(floor(times)) && time <= max(ceil(times)))                    
                        xInterp = obj.xInterps{i};
                        x = xInterp(time);
                        
                        yInterp = obj.yInterps{i};
                        y = yInterp(time);
                        
                        zInterp = obj.zInterps{i};
                        z = zInterp(time);
                        
                        evtColor = obj.evtColors(i).color;
                        hold(hAx,'on');
                        l = plot3(hAx, x,y,z, 'd', 'MarkerEdgeColor','k', 'MarkerFaceColor',evtColor);
                        obj.markerPlot(end+1) = l;
                        hold(hAx,'off');

                        [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(time);
                        epochStr = string(formDateStr(year, day, hour, minute, sec));
                        l.DataTipTemplate.DataTipRows = [dataTipTextRow("Epoch", epochStr);
                                                         dataTipTextRow("X Pos [km]", x);
                                                         dataTipTextRow("Y Pos [km]", y);
                                                         dataTipTextRow("Z Pos [km]", z)];
                    end
                end
            end
        end
    end
end