classdef LaunchVehicleViewProfileGrdTrackSunLighting < matlab.mixin.SetGet
    %LaunchVehicleViewProfileGrdTrackSunLighting Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(SetObservable)
        dAxes matlab.graphics.axis.Axes
        bodyInfo KSPTOT_BodyInfo
        hGrdTrkNightPatch(1,:) matlab.graphics.primitive.Patch = matlab.graphics.primitive.Patch.empty(1,0);
        showLighting(1,1) logical = false;

        hGrdTrkSunLoc(1,:) matlab.graphics.chart.primitive.Line = matlab.graphics.chart.primitive.Line.empty(1,0);
    end
    
    methods
        function obj = LaunchVehicleViewProfileGrdTrackSunLighting(dAxes, bodyInfo, showLighting)
            obj.dAxes = dAxes;
            obj.bodyInfo = bodyInfo;
            obj.showLighting = showLighting;
        end

        function updateSunLightingPosition(obj, time)
            if(not(isempty(obj)) && not(isempty(obj.bodyInfo)))
                sunBodyInfo = obj.bodyInfo.celBodyData.getTopLevelBody();
                ce = sunBodyInfo.getElementSetsForTimes(time);
                ge = ce.convertToFrame(obj.bodyInfo.getBodyFixedFrame()).convertToGeographicElementSet();

                hourAngle = -ge.long;
                declination = ge.lat;

                if(obj.showLighting)
                    if(not(isempty(obj.hGrdTrkNightPatch)) && isvalid(obj.hGrdTrkNightPatch))
                        [x, latitude] = getPatchLongLatPoints(hourAngle, declination);
                        obj.hGrdTrkNightPatch.XData = x;
                        obj.hGrdTrkNightPatch.YData = latitude;
                        obj.hGrdTrkNightPatch.Visible = "on";
                    else
                        obj.plotNightLatLongArea(hourAngle, declination);
                        obj.hGrdTrkNightPatch.Visible = "on";
                    end

                    if(not(isempty(obj.hGrdTrkSunLoc)) && isvalid(obj.hGrdTrkSunLoc))
                        obj.hGrdTrkSunLoc.XData = wrapTo180(rad2deg(ge.long));
                        obj.hGrdTrkSunLoc.YData = rad2deg(ge.lat);
                        obj.hGrdTrkSunLoc.Visible = "on";
                    else
                        obj.hGrdTrkSunLoc = plot(obj.dAxes, wrapTo180(rad2deg(ge.long)), rad2deg(ge.lat), 'Marker','o','MarkerFaceColor','y', 'MarkerEdgeColor','none');
                    end

                    obj.hGrdTrkSunLoc.DataTipTemplate.DataTipRows = [dataTipTextRow('Sun Longitude [deg]:', wrapTo180(rad2deg(ge.long))), ...
                                                                     dataTipTextRow('Sun Latitude [deg]:', rad2deg(ge.lat))];

                else
                    if(not(isempty(obj.hGrdTrkNightPatch)) && isvalid(obj.hGrdTrkNightPatch))
                        obj.hGrdTrkNightPatch.Visible = "off";
                    end

                    if(not(isempty(obj.hGrdTrkSunLoc)) && isvalid(obj.hGrdTrkSunLoc))
                        obj.hGrdTrkSunLoc.Visible = "off";
                    end
                end
            end
        end

        function plotNightLatLongArea(obj, hourAngle, declination)
            [x, latitude] = getPatchLongLatPoints(hourAngle, declination);
            obj.hGrdTrkNightPatch = fill(obj.dAxes, x,latitude, 'k', 'FaceAlpha',0.25, 'EdgeColor','none');
            obj.hGrdTrkNightPatch.HitTest ="off";
            obj.hGrdTrkNightPatch.PickableParts = "none";
        end
    end
end

function [x, latitude] = getTerminator(hourAngle, declination)
    %Source: http://www.geoastro.de/map/index.html
		% for (int i=-180; i<=180; i++) {
		% 	longitude=i+tau;
		% 	tanLat = - Math.cos(longitude*K)/Math.tan(dec*K);						
		% 	arctanLat = Math.atan(tanLat)/K;
		% 	y1 = y0-(int)Math.round(arctanLat);
        % 
		% 	longitude=longitude+1;
		% 	tanLat = - Math.cos(longitude*K)/Math.tan(dec*K);
		% 	arctanLat = Math.atan(tanLat)/K;
		% 	y2 = y0-(int)Math.round(arctanLat);
        % 
		% 	g.drawLine(x0+i,y1,x0+i+1,y2);
		% }
        
    x = deg2rad(linspace(-180,180,10000));
    longitude = x + hourAngle;
    latitude = atan(-cos(longitude)/tan(declination));
end

function [x, latitude] = getPatchLongLatPoints(hourAngle, declination)
    [x, latitude] = getTerminator(hourAngle, declination);
    
    if(declination == 0)
        x = [-pi x pi];
        latitude = [-pi/2 latitude -pi/2];
    else
        x = [-pi x pi];
        if(declination <= 0)
            latitude = [pi/2 latitude pi/2];
        else
            latitude = [-pi/2 latitude -pi/2];
        end
    end

    x = rad2deg(x);
    latitude = rad2deg(latitude);
end