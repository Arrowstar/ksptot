classdef Generic2DGroundTrackViewType < AbstractTrajectoryViewType
    %Generic2DGroundTrackViewType Summary of this class goes here
    %   Detailed explanation goes here
    
    properties

    end
    
    methods
        function obj = Generic2DGroundTrackViewType()
            
        end

        function plotGroundTrack(obj, lvdData, lvdApp)
            arguments
                obj(1,1) Generic2DGroundTrackViewType
                lvdData(1,1) LvdData
                lvdApp(1,1) ma_LvdMainGUI_App
            end 

            global GLOBAL_AppThemer %#ok<GVMIS>

            %Reset axes
            dAxes = lvdApp.GroundTrackAxes;
            cla(dAxes,'reset');
            hold(dAxes, 'on');
            
            %Grab important properties for reuse
            viewProfile = lvdData.viewSettings.selViewProfile;

            %Set allowed interactions
            disableDefaultInteractivity(dAxes);
            dAxes.Interactions = [regionZoomInteraction('Dimensions','xy'), dataTipInteraction];

            %Place image of central body on axes
            originBody = viewProfile.frame.getOriginBody();
            I = originBody.getSurfaceTexture();

            %Reset relevant view profile properties
            viewProfile.vehicleGrdTrackData = LaunchVehicleViewProfileVehicleGrdTrkData();
            viewProfile.grdObjGrdTrackData = LaunchVehicleViewProfileGrdTrkGroundObjData.empty(1,0);
            viewProfile.celBodyGrdTrackData = LaunchVehicleViewProfileGrdTrkCelBodyData.empty(1,0);
            viewProfile.grdTrackLighting = LaunchVehicleViewProfileGrdTrackSunLighting(dAxes, originBody, viewProfile.showLighting);

            if(not(isempty(I)))
                im = image(dAxes, [-180 180], [-90 90], I);
                im.PickableParts = "none";
                im.HitTest = "off";
            else
                dAxes.Color = originBody.getBodyRGB();
            end
            dAxes.YDir = "normal";

            %Make sure we're looking straight on
            view(dAxes,2);

            %Set ground track label
            lvdApp.GroundTrackLabel.Text = sprintf('%s Ground Track', originBody.name);

            %Set axes labels, limits, and grids appropriately
            %Turn on hold for subsequent plotting
            xlabel(dAxes, 'Longitude [deg]');
            ylabel(dAxes, 'Latitude [deg]');
            xlim(dAxes, [-180, 180]);
            ylim(dAxes, [-90, 90]);
            xticks(dAxes, -180:30:180);
            yticks(dAxes, -90:15:90);
            grid(dAxes,'on');
            
            %Plot grid since the grid function doesn't work with an image
            for row = dAxes.YTick
                yl = yline(dAxes, row, 'Color',dAxes.GridColor, 'LineWidth',0.25, 'LineStyle','--', 'Alpha',0.5);
                yl.PickableParts = "none"; 
                yl.HitTest="off";
            end
            for col = dAxes.XTick
                xl = xline(dAxes, col, 'Color',dAxes.GridColor, 'LineWidth',0.25, 'LineStyle','--', 'Alpha',0.5);
                xl.PickableParts = "none"; 
                xl.HitTest="off";
            end

            %Plot terrain elevation contour map, if user desires
            hgi = originBody.getHeightMap();
            if(viewProfile.showTerrainContours && not(isempty(hgi)))               
                lat = linspace(-pi/2,pi/2,1000);
                long = linspace(-pi,pi,1000);
                [LAT,LONG] = meshgrid(lat,long);
                LAT = LAT';
                LONG = LONG';
    
                Z = flipud(hgi(LAT, LONG));

                if(all(Z == 0,"all"))
                    warning('When plotting ground track terrain contour map, all elevations were zero.  No terrain has been loaded for %s.', originBody.name);
                end

                %Compute the slope at each point
                oRad = originBody.radius;

                longDirRad = (long(2) - long(1));
                lonDirHKm = longDirRad * oRad;
                latDirHRad = (lat(2) - lat(1));
                latDirHKm = latDirHRad * oRad;
                [GX,GY] = gradient(Z, lonDirHKm, latDirHKm); %km/km

                %  Compute the three points needed to find the plane whose
                %  normal vector we are looking for
                P1 = cat(3, LONG*oRad, LAT*oRad, Z);

                P2 = P1;
                P2(:,:,1) = P2(:,:,1) + lonDirHKm;
                P2(:,:,3) = P2(:,:,3) + GX;

                P3 = P1;
                P3(:,:,2) = P3(:,:,2) + latDirHKm;
                P3(:,:,3) = P3(:,:,3) + GY;

                Dir = cross((P2 - P1), (P3 - P1), 3);
                DirMag = vecnorm(Dir,2,3);
                DirNorm = Dir .* (1./DirMag);

                upVect = zeros(1,1,3);
                upVect(1,1,3) = 1;
                upVectMat = repmat(upVect, width(DirNorm), height(DirNorm));
                slopeAngles = rad2deg(atan2(vecnorm(cross(DirNorm,upVectMat,3),2,3), dot(DirNorm,upVectMat,3)));

                %Create contour plot and set data labels
                [~,c] = contourf(dAxes, rad2deg(LONG), rad2deg(LAT), Z, viewProfile.numTerrainContourLevels, '-');
                c.DataTipTemplate.DataTipRows(1).Label = 'Longitude [deg]';
                c.DataTipTemplate.DataTipRows(2).Label = 'Latitude [deg]';
                c.DataTipTemplate.DataTipRows(3).Label = 'Terrain Elevation [km]';
                c.DataTipTemplate.DataTipRows(4) = dataTipTextRow("Slope [deg]", slopeAngles, '%0.3f');
                c.FaceAlpha = 0.25;
                c.EdgeAlpha = 0.20;
                colormap(dAxes, 'gray');

                %Create contour plot color bar
                cb = contourcbar(dAxes, "eastoutside", "HitTest","off", "PickableParts","none");
                cb.Label.String = "Terrain Elevation [km]";
            end

            %Plot ground track
            entries = lvdData.stateLog.getAllEntries();
            ce = entries.getCartesianElementSetRepresentation();
            ceBodyFixed = ce.convertToFrame(originBody.getBodyFixedFrame());
            ge = ceBodyFixed.convertToGeographicElementSet();

            intGrps = [entries.integrationGroup];
            intGrpNums = [intGrps.integrationGroupNum];
            [intGrpNums, I] = sort(intGrpNums);
            uniqueIntGrpNums = unique(intGrpNums);
            entries = entries(I);
            ge = ge(I);

            for(intGrpNum=uniqueIntGrpNums)
                bool = intGrpNums == intGrpNum;
                subGE = ge(bool);
                subEntries = entries(bool);
                
                event = subEntries(1).event;
                plotLineColor = event.colorLineSpec.color.color;
                plotLineStyle = event.colorLineSpec.lineSpec.linespec;
                plotLineWidth = event.colorLineSpec.lineWidth;
                plotMarkerType = event.colorLineSpec.markerSpec.shape;
                plotMarkerSize = event.colorLineSpec.markerSize;
                plotMethodEnum = event.plotMethod;

                allTimes = [subGE.time];
                allLongsDeg = wrapTo180(rad2deg([subGE.long]));
                allLatsDeg = rad2deg([subGE.lat]);
                allAltsKm = [subGE.alt];

                [line, subLongsDegOut, subLatsDegOut, subAltsKmOut, subTimesOut] = plotLatLongWithAngleWrapping(allTimes, allLongsDeg, allLatsDeg, allAltsKm, dAxes, plotLineColor, plotLineStyle, plotLineWidth, plotMarkerType, plotMarkerSize, plotMethodEnum);
                
                line.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow("Event", repmat(string(event.getListboxStr()), size(line.XData)));
                
                for(j=1:length(subLongsDegOut))
                    if(numel(subLongsDegOut{j}) > 0 && numel(subLatsDegOut{j}) > 0 && numel(subAltsKmOut{j}) > 0 && numel(subTimesOut{j}) > 0)
                        viewProfile.vehicleGrdTrackData.addData(subTimesOut{j}, subLongsDegOut{j}, subLatsDegOut{j}, subAltsKmOut{j}, event.colorLineSpec.color);
                    end
                end
            end

            %plot celestial bodies
            minTime = min([entries.time]);
            maxTime = max([entries.time]);
            if(viewProfile.showCelestialBodyGrdTracks)
                for(i=1:length(viewProfile.bodiesToPlot))
                    bodyToPlot = viewProfile.bodiesToPlot(i);
    
                    if(bodyToPlot == originBody)
                        continue;
                    end
    
                    celBodyGrdTrackData = LaunchVehicleViewProfileGrdTrkCelBodyData(bodyToPlot);
                    viewProfile.celBodyGrdTrackData(end+1) = celBodyGrdTrackData;
    
                    bodyOrbitPeriod = [];
                    if(bodyToPlot.sma > 0)
                        gmu = bodyToPlot.getParentGmuFromCache();
                        
                        if(not(isempty(gmu)) && not(isnan(gmu)) && isfinite(gmu))
                            bodyOrbitPeriod = computePeriod(bodyToPlot.sma, gmu);
                        end
                    else
                        bodyOrbitPeriod = Inf;
                    end
    
                    if(isfinite(bodyOrbitPeriod))
                        numPeriods = (maxTime - minTime)/bodyOrbitPeriod;
                        times = linspace(minTime, maxTime, max(10*numPeriods, numel(entries)));
                    else
                        times = linspace(minTime, maxTime, numel(entries));
                    end
    
                    ce = bodyToPlot.getElementSetsForTimes(times);
                    ceBodyFixed = ce.convertToFrame(originBody.getBodyFixedFrame());
                    ge = ceBodyFixed.convertToGeographicElementSet();
    
                    allLongsDeg = wrapTo180(rad2deg([ge.long]));
                    allLatsDeg = rad2deg([ge.lat]);
                    allAltsKm = [ge.alt];
    
                    bodyColor = bodyToPlot.getBodyRGB();
    
                    plotLineColor = bodyColor;
                    plotLineStyle = '-';
                    plotLineWidth = 1.5;
                    plotMarkerType = "none";
                    plotMarkerSize = 1;
                    plotMethodEnum = EventPlottingMethodEnum.PlotContinuous;
    
                    [line, subLongsDegOut, subLatsDegOut, subAltsKmOut, subTimesOut] = plotLatLongWithAngleWrapping(times, allLongsDeg, allLatsDeg, allAltsKm, dAxes, plotLineColor, plotLineStyle, plotLineWidth, plotMarkerType, plotMarkerSize, plotMethodEnum);
                    
                    line.DataTipTemplate.DataTipRows = [dataTipTextRow("Celestial Body", repmat(string(bodyToPlot.name), size(line.XData))); ...
                                                        line.DataTipTemplate.DataTipRows];
                    for(j=1:length(subLongsDegOut))
                        if(numel(subLongsDegOut{j}) > 0 && numel(subLatsDegOut{j}) > 0 && numel(subAltsKmOut{j}) > 0 && numel(subTimesOut{j}) > 0)
                            celBodyGrdTrackData.addData(subTimesOut{j}, subLongsDegOut{j}, subLatsDegOut{j}, subAltsKmOut{j});
                        end
                    end
                end
            end

            %Plot ground objects on body
            if(viewProfile.showGroundObjsGrdTracks)
                for(i=1:length(viewProfile.groundObjsToPlot))
                    grdObj = viewProfile.groundObjsToPlot(i);
                    geomPtGrdTrackData = LaunchVehicleViewProfileGrdTrkGroundObjData(grdObj);
                    viewProfile.grdObjGrdTrackData(end+1) = geomPtGrdTrackData;
    
                    waypts = grdObj.wayPts;
                    totalTransitTime = [waypts.timeToNextWayPt];
                    numPtsToPlot = min(min(totalTransitTime), 100);
    
                    times = linspace(minTime, maxTime, numPtsToPlot);
                    ge = GeographicElementSet.empty(1,0);
                    for(j=1:length(times))
                        ge(j) = grdObj.getStateAtTime(times(j));
                    end
                    ge = ge.convertToFrame(originBody.getBodyFixedFrame());
                    
                    allLongsDeg = wrapTo180(rad2deg([ge.long]));
                    allLatsDeg = rad2deg([ge.lat]);
                    allAltsKm = [ge.alt];
    
                    plotLineColor = grdObj.grdTrkLineColor.color;
                    plotLineStyle = grdObj.grdTrkLineSpec.linespec;
                    plotLineWidth = 1.5;
                    plotMarkerType = "none";
                    plotMarkerSize = 1;
                    plotMethodEnum = EventPlottingMethodEnum.PlotContinuous;
    
                    [line, subLongsDegOut, subLatsDegOut, subAltsKmOut, subTimesOut] = plotLatLongWithAngleWrapping(times, allLongsDeg, allLatsDeg, allAltsKm, dAxes, plotLineColor, plotLineStyle, plotLineWidth, plotMarkerType, plotMarkerSize, plotMethodEnum);
                    
                    line.DataTipTemplate.DataTipRows = [dataTipTextRow("Ground Object", repmat(string(grdObj.name), size(line.XData))); ...
                                                            dataTipTextRow("Celestial Body", repmat(string(grdObj.centralBodyInfo.name), size(line.XData))); ...
                                                            line.DataTipTemplate.DataTipRows];
                    for(j=1:length(subLongsDegOut))
                        if(numel(subLongsDegOut{j}) > 0 && numel(subLatsDegOut{j}) > 0 && numel(subAltsKmOut{j}) > 0 && numel(subTimesOut{j}) > 0)
                            geomPtGrdTrackData.addData(subTimesOut{j}, subLongsDegOut{j}, subLatsDegOut{j}, subAltsKmOut{j});
                        end
                    end
                end
            end

            %Plot geometric points on body
            entries = lvdData.stateLog.getAllEntries();
            allTimes = unique([entries.time], 'sorted');
            if(viewProfile.showGeomPointsGrdTracks)
                for(i=1:length(viewProfile.pointsToPlot))
                    pointToPlot = viewProfile.pointsToPlot(i);
    
                    if(pointToPlot.canBePlotted)
                        geomPtGrdTrackData = LaunchVehicleViewProfileGrdTrkGeomPointData(pointToPlot);
                        viewProfile.geomPtGrdTrackData(end+1) = geomPtGrdTrackData;
    
                        ce = pointToPlot.getPositionAtTime(allTimes, [], originBody.getBodyFixedFrame());
                        ceBodyFixed = ce.convertToFrame(originBody.getBodyFixedFrame());
                        ge = ceBodyFixed.convertToGeographicElementSet();
        
                        allLongsDeg = wrapTo180(rad2deg([ge.long]));
                        allLatsDeg = rad2deg([ge.lat]);
                        allAltsKm = [ge.alt];
        
                        plotLineColor = pointToPlot.trkLineColor.color;
                        plotLineStyle = pointToPlot.trkLineSpec.linespec;
                        plotLineWidth = 1.5;
                        plotMarkerColor = pointToPlot.markerColor.color;
                        plotMarkerType = pointToPlot.markerShape.shape;
                        plotMarkerSize = 1;
                        plotMethodEnum = EventPlottingMethodEnum.PlotContinuous;
        
                        [line, subLongsDegOut, subLatsDegOut, subAltsKmOut, subTimesOut] = plotLatLongWithAngleWrapping(allTimes, allLongsDeg, allLatsDeg, allAltsKm, dAxes, plotLineColor, plotLineStyle, plotLineWidth, plotMarkerType, plotMarkerSize, plotMethodEnum);
                        
                        line.MarkerFaceColor = plotMarkerColor;
                        line.DataTipTemplate.DataTipRows = [dataTipTextRow("Geometric Point", repmat(string(pointToPlot.name), size(line.XData))); ...
                                                            line.DataTipTemplate.DataTipRows];
                        
                        for(j=1:length(subLongsDegOut))
                            if(numel(subLongsDegOut{j}) > 0 && numel(subLatsDegOut{j}) > 0 && numel(subAltsKmOut{j}) > 0 && numel(subTimesOut{j}) > 0)
                                geomPtGrdTrackData.addData(subTimesOut{j}, subLongsDegOut{j}, subLatsDegOut{j}, subAltsKmOut{j});
                            end
                        end
                    end
                end
            end

            %Re-theme app if necessary
            if(viewProfile.useThemeForAxes)
                GLOBAL_AppThemer.themeWidget(dAxes, GLOBAL_AppThemer.selTheme);
                GLOBAL_AppThemer.themeWidget(lvdApp.GroundTrackDisplayAxesGridLayout, GLOBAL_AppThemer.selTheme);
            end
        end
    end
end

function [line, subLongsDegOut, subLatsDegOut, subAltsKmOut, subTimesOut] = plotLatLongWithAngleWrapping(allTimes, allLongsDeg, allLatsDeg, allAltsKm, dAxes, plotLineColor, plotLineStyle, plotLineWidth, plotMarkerType, plotMarkerSize, plotMethodEnum)
    line = matlab.graphics.GraphicsPlaceholder.empty(1,0);
    subLongsDegOut = {};
    subLatsDegOut = {};
    subTimesOut = {};
    subAltsKmOut = {};

    allT = [];
    allX = [];
    allY = [];
    allZ = [];

    %filter out non-unique points
    A = unique([allTimes; allLongsDeg; allLatsDeg; allAltsKm]','rows', 'stable')';
    allTimes = A(1,:);
    allLongsDeg = A(2,:);
    allLatsDeg = A(3,:);
    allAltsKm = A(4,:);

    %we need to split the plots so that we don't get wrapping
    %on the graph itself
    longJumpBool = abs(allLongsDeg(2:end) - allLongsDeg(1:end-1)) > 90;
    longJumpInds = find(longJumpBool);
    jumpDetected = not(isempty(longJumpInds));

    longJumpInds = [longJumpInds, numel(allLongsDeg)]; %#ok<AGROW>
    
    curLongStart = 1;
    for(j=1:length(longJumpInds))
        longJumpInd = longJumpInds(j);
        subTimes = allTimes(curLongStart : longJumpInd);
        subLongsDeg = allLongsDeg(curLongStart : longJumpInd);
        subLatsDeg = allLatsDeg(curLongStart : longJumpInd);
        subAltsKm = allAltsKm(curLongStart : longJumpInd);

        if(all(subTimes(1) == subTimes(2:end)))
            subTimes = subTimes(1);
            subLongsDeg = subLongsDeg(1);
            subLatsDeg = subLatsDeg(1);
            subAltsKm = subAltsKm(1);
        end

        %we need to generate missing data up to the edges of
        %the graph (long = +/- 180) or things might look weird
        %when plotted
        if(jumpDetected && numel(subLongsDeg) >= 2)
            medianLongDiff = abs(median(diff(subLongsDeg))/10);

            if(j == 1)
                if(subLongsDeg(end) > 0)
                    newPreLongPtsToAdd = [];
                    newPostLongPtsToAdd = [subLongsDeg(end) : medianLongDiff : 180, 180];
                else
                    newPreLongPtsToAdd = [];
                    newPostLongPtsToAdd = [subLongsDeg(end) : -medianLongDiff : -180, -180];
                end

            elseif(j >= 2 && j < length(longJumpInds))
                if(subLongsDeg(end) > 0)
                    newPostLongPtsToAdd = [subLongsDeg(end) : medianLongDiff : 180, 180];
                else
                    newPostLongPtsToAdd = [subLongsDeg(end) : -medianLongDiff : -180, -180];
                end

                if(subLongsDeg(1) > 0)
                    newPreLongPtsToAdd = [180 : -medianLongDiff : subLongsDeg(1), subLongsDeg(1)];
                else
                    newPreLongPtsToAdd = [-180 : medianLongDiff : subLongsDeg(1), subLongsDeg(1)];
                end
                
            else %j == length(longJumpInds)
                if(subLongsDeg(1) > 0)
                    newPreLongPtsToAdd = [180 : -medianLongDiff : subLongsDeg(1), subLongsDeg(1)];
                    newPostLongPtsToAdd = [];
                else
                    newPreLongPtsToAdd = [-180 : medianLongDiff : subLongsDeg(1), subLongsDeg(1)];
                    newPostLongPtsToAdd = [];
                end
            end

            if(numel(subLongsDeg) >= 4)
                method = 'pchip';
            else
                method = 'makima';
            end

            try
                newPreLatPtsToAdd = interp1(subLongsDeg, subLatsDeg, newPreLongPtsToAdd, method, 'extrap');
                newPostLatPtsToAdd = interp1(subLongsDeg, subLatsDeg, newPostLongPtsToAdd, method, 'extrap');
    
                newPreTimesToAdd = interp1(subLongsDeg, subTimes, newPreLongPtsToAdd, method, 'extrap');
                newPostTimesToAdd = interp1(subLongsDeg, subTimes, newPostLongPtsToAdd, method, 'extrap');
    
                newPreAltsToAdd = interp1(subLongsDeg, subAltsKm, newPreLongPtsToAdd, method, 'extrap');
                newPostAltsToAdd = interp1(subLongsDeg, subAltsKm, newPostLongPtsToAdd, method, 'extrap');
            catch ME
                newPreLongPtsToAdd = [];
                newPostLongPtsToAdd = [];
                newPreLatPtsToAdd = [];
                newPostLatPtsToAdd = [];
                newPreTimesToAdd = [];
                newPostTimesToAdd = [];
                newPreAltsToAdd = [];
                newPostAltsToAdd = [];
            end

            subLongsDeg = [newPreLongPtsToAdd, subLongsDeg, newPostLongPtsToAdd]; %#ok<AGROW>
            subLatsDeg = [newPreLatPtsToAdd, subLatsDeg, newPostLatPtsToAdd]; %#ok<AGROW>
            subTimes = [newPreTimesToAdd, subTimes, newPostTimesToAdd]; %#ok<AGROW>
            subAltsKm = [newPreAltsToAdd, subAltsKm, newPostAltsToAdd]; %#ok<AGROW>
        end
        
        switch plotMethodEnum
            case EventPlottingMethodEnum.PlotContinuous
                t = subTimes;
                x = subLongsDeg;
                y = subLatsDeg;
                z = subAltsKm;
                    
            case EventPlottingMethodEnum.SkipFirstState
                t = subTimes(2:end);
                x = subLongsDeg(2:end);
                y = subLatsDeg(2:end);
                z = subAltsKm(2:end);

            case EventPlottingMethodEnum.DoNotPlot
                t = [];
                x = [];
                y = [];
                z = [];

            otherwise
                error('Unknown event plotting method enum: %s', plotMethodEnum.name);
        end

        allT = horzcat(allT,NaN,t); %#ok<AGROW>
        allX = horzcat(allX,NaN,x); %#ok<AGROW>
        allY = horzcat(allY,NaN,y); %#ok<AGROW>
        allZ = horzcat(allZ,NaN,z); %#ok<AGROW>

        subLongsDegOut{j} = x; %#ok<AGROW>
        subLatsDegOut{j} = y; %#ok<AGROW>
        subAltsKmOut{j} = z; %#ok<AGROW>
        subTimesOut{j} = t; %#ok<AGROW>

        curLongStart = longJumpInd + 1;
    end

    l = plot(dAxes, allX, allY, 'Color', plotLineColor, 'LineStyle', plotLineStyle, 'LineWidth',plotLineWidth, 'Marker',plotMarkerType, 'MarkerSize',plotMarkerSize, 'MarkerEdgeColor','none', 'MarkerFaceColor',plotLineColor);
    
    if(not(isempty(l)))
        tString = string.empty(1,0);
        for(k=1:length(allT))
            [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(allT(k));
            tString(k) = formDateStr(year, day, hour, minute, sec);
        end

        l.DataTipTemplate.DataTipRows = [dataTipTextRow("Epoch", tString); ...
                                         dataTipTextRow('Longitude [deg]', allX); ...
                                         dataTipTextRow('Latitude [deg]', allY); ...
                                         dataTipTextRow('Altitude [km]', allZ)];
        line = l;
    end
end