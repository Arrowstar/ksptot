classdef LaunchVehicleViewProfileVehicleGrdTrkData < matlab.mixin.SetGet
    %LaunchVehicleViewProfileVehicleGrdTrkData Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        timesArr(1,:) cell = {};
        lonInterps(1,:) cell = {};
        latInterps(1,:) cell = {};
        altInterps(1,:) cell = {};
        
        evtColors(1,:) ColorSpecEnum = ColorSpecEnum.empty(1,0);
        markerPlot = matlab.graphics.chart.primitive.Line.empty(1,0)
    end
    
    methods
        function obj = LaunchVehicleViewProfileVehicleGrdTrkData()

        end
        
        function addData(obj, times, lons, lats, alts, evtColor)
            if(length(unique(times)) == 1)
                times = [times, times+10*eps(times(1))];
                lats = [lats; lats];
                lons = [lons; lons];
                alts = [alts; alts];
            end

            times = times(:);
            lats = lats(:);
            lons = lons(:);
            alts = alts(:);

            [times, ia, ~] = unique(times, 'stable');
            lats = lats(ia);
            lons = lons(ia);
            alts = alts(ia);

            [times, I] = sort(times);
            lats = lats(I);
            lons = lons(I);
            alts = alts(I);

            obj.timesArr(end+1) = {times};
            
            if(length(times) >= 3)
                method = 'pchip';
            else
                method = 'linear';
            end
           
            try
                obj.lonInterps{end+1} = griddedInterpolant(times, lons, method, 'linear');
                obj.latInterps{end+1} = griddedInterpolant(times, lats, method, 'linear');
                obj.altInterps{end+1} = griddedInterpolant(times, alts, method, 'linear');
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
                        lonInterp = obj.lonInterps{i};
                        lon = lonInterp(time);
                        
                        latInterp = obj.latInterps{i};
                        lat = latInterp(time);

                        altInterp = obj.altInterps{i};
                        alt = altInterp(time);
                        
                        evtColor = obj.evtColors(i).color;
                        l = plot(hAx, lon,lat, 'd', 'MarkerEdgeColor','k', 'MarkerFaceColor',evtColor);
                        obj.markerPlot(end+1) = l;

                        [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(time);
                        tString = string(formDateStr(year, day, hour, minute, sec));
                                                
                        l.DataTipTemplate.DataTipRows = [dataTipTextRow("Epoch", tString); 
                                                         dataTipTextRow("Longitude [deg]", lon);
                                                         dataTipTextRow("Latitude [deg]", lat);
                                                         dataTipTextRow("Altitude [km]", alt)];
                    end
                end
            end
        end
    end
end