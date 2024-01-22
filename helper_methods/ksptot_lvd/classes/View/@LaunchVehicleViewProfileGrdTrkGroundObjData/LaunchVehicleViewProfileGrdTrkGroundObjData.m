classdef LaunchVehicleViewProfileGrdTrkGroundObjData < matlab.mixin.SetGet
    %LaunchVehicleViewProfileGrdTrkGroundObjData Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        groundObj LaunchVehicleGroundObject
        
        timesArr(1,:) cell = {};
        lonInterps(1,:) cell = {};
        latInterps(1,:) cell = {};
        altInterps(1,:) cell = {};
        
        markerPlot = matlab.graphics.chart.primitive.Line.empty(1,0);
    end
    
    methods
        function obj = LaunchVehicleViewProfileGrdTrkGroundObjData(groundObj)
            obj.groundObj = groundObj;
            obj.markerPlot = matlab.graphics.GraphicsPlaceholder.empty(1,0);
        end
        
        function addData(obj, times, lons, lats, alts)
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
            
            obj.lonInterps{end+1} = griddedInterpolant(times, lons, 'spline', 'linear');
            obj.latInterps{end+1} = griddedInterpolant(times, lats, 'spline', 'linear');
            obj.altInterps{end+1} = griddedInterpolant(times, alts, 'spline', 'linear');
        end
        
        function plotGrdObjMarkerAtTime(obj, time, hAx)   
            % delete(obj.markerPlot);
            for(i=1:length(obj.timesArr))
                times = obj.timesArr{i};
                
                if(time >= min(floor(times)) && time <= max(ceil(times)))
                    lonInterp = obj.lonInterps{i};
                    lonGrd = lonInterp(time);
                    
                    latInterp = obj.latInterps{i};
                    latGrd = latInterp(time);

                    altInterp = obj.altInterps{i};
                    alt = altInterp(time);

                    if(not(isempty(obj.markerPlot)) && isvalid(obj.markerPlot))
                        obj.markerPlot.XData = lonGrd;
                        obj.markerPlot.YData = latGrd;
                    else
                        obj.markerPlot = plot(hAx, lonGrd,latGrd, 'MarkerEdgeColor','k', 'Marker',obj.groundObj.markerShape.shape, 'MarkerFaceColor',obj.groundObj.markerColor.color);
                        % obj.markerPlot = l;
                    end

                    [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(time);
                    tString = string(formDateStr(year, day, hour, minute, sec));

                    obj.markerPlot.DataTipTemplate.DataTipRows = [dataTipTextRow("Ground Object", repmat(string(obj.groundObj.name), size(obj.markerPlot.XData)));
                                                                  dataTipTextRow("Celestial Body", repmat(string(obj.groundObj.centralBodyInfo.name), size(obj.markerPlot.XData)));
                                                                  dataTipTextRow("Epoch", tString); 
                                                                  dataTipTextRow("Longitude [deg]", lonGrd);
                                                                  dataTipTextRow("Latitude [deg]", latGrd);
                                                                  dataTipTextRow('Altitude [km]', alt)];
                end
            end
        end
    end
end