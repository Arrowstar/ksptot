classdef Mercator2DTrajectoryViewType < AbstractTrajectoryViewType
    %Inertial3DTrajectoryViewType Summary of this class goes here
    %   Detailed explanation goes here
    
    properties

    end
    
    methods
        function obj = Mercator2DTrajectoryViewType()
            
        end
        
        function [hCBodySurf, childrenHGs] = plotStateLog(obj, orbitNumToPlot, lvdData, viewProfile, handles)
            dAxes = handles.dispAxes;
            hFig = handles.ma_LvdMainGUI;
            celBodyData = lvdData.celBodyData;
            stateLog = lvdData.stateLog;
            hCBodySurf = [];
            
            axes(dAxes);
            cla(gca);
            
            if(stateLog.getNumberOfEntries() == 0)
                return;
            end
            
            switch viewProfile.trajEvtsViewType
                case ViewEventsTypeEnum.SoIChunk
                    maStateLog = stateLog.getMAFormattedStateLogMatrix();

                    chunkedStateLog = breakStateLogIntoSoIChunks(maStateLog);
                    if(orbitNumToPlot > size(chunkedStateLog,1))
                        orbitNumToPlot = size(chunkedStateLog,1);
                        set(dAxes,'UserData',orbitNumToPlot);
                    end
                    subStateLogs = chunkedStateLog(orbitNumToPlot,:);

                    curMissionSegStr = num2str(orbitNumToPlot);
                    totalMissionSegStr = num2str(size(chunkedStateLog,1));
                
                case ViewEventsTypeEnum.All
                    viewCentralBody = viewProfile.viewCentralBody;
                    viewInFrame = BodyCenteredInertialFrame(viewCentralBody, celBodyData);

                    entries = stateLog.getAllEntries();
                    subStateLogsMat = NaN(length(entries), 13);
                    for(i=1:length(entries))
                        tempMaMatrix = entries(i).getMAFormattedStateLogMatrix();

                        cartesianEntry = entries(i).getCartesianElementSetRepresentation();
                        cartesianEntry = cartesianEntry.convertToFrame(viewInFrame); 

                        subStateLogsMat(i,:) = [entries(i).time, cartesianEntry.rVect', cartesianEntry.vVect', viewCentralBody.id, tempMaMatrix(9:13)];
                    end

                    subStateLogs = {};
                    for(evtNum=1:max(subStateLogsMat(:,13)))
                        subStateLogs{evtNum} = subStateLogsMat(subStateLogsMat(:,13) == evtNum,:); %#ok<AGROW>
                    end

                    curMissionSegStr = num2str(1);
                    totalMissionSegStr = num2str(1);
                otherwise
                    error('Unknown trajectory view type when plotting trajectory: %s', viewProfile.trajViewType.name);
            end
            
            eventsList = [];
            minTime = Inf;
            maxTime = -Inf;
            
            latLongAltSubStateLogs = subStateLogs;
            for(i=1:length(subStateLogs))
                if(~isempty(subStateLogs{i}))
                    eventsList = [eventsList;unique(subStateLogs{i}(:,13))]; %#ok<AGROW>
                end
                if(i>1)
                    prevSubStateLog = subStateLogs{i-1};
                else
                    prevSubStateLog = NaN(1,size(subStateLogs{i},2));
                end
                
                bodyInfo = getBodyInfoByNumber(subStateLogs{1}(1,8), celBodyData);
                for(j=1:length(subStateLogs{i}(:,1)))
                    [lat, long, ~, ~, ~, ~, ~, ~, ~] = getLatLongAltFromInertialVect(subStateLogs{i}(j,1), ...
                                                                                     subStateLogs{i}(j,2:4)', ...
                                                                                     bodyInfo);
                    latLongAltSubStateLogs{i}(j,2:4) = [rad2deg(long), rad2deg(lat), 0];
                end

                if(size(subStateLogs{i},1)>1)
                    showSoI = viewProfile.showSoIRadius;
                    showChildBodies = viewProfile.showChildBodyOrbits;
                    showChildMarker = viewProfile.showChildBodyMarkers;
                    [childrenHGs] = plotSubStateLog(subStateLogs{i}, prevSubStateLog, showSoI, showChildBodies, showChildMarker, lvdData, celBodyData, dAxes);
                    
                    minTime = min([minTime, min(subStateLogs{i}(:,1))]);
                    maxTime = max([maxTime, max(subStateLogs{i}(:,1))]);
                end
            end
                        
%             viewProfile.createBodyMarkerData(dAxes, latLongAltSubStateLogs, viewInFrame);
            viewProfile.createTrajectoryMarkerData(latLongAltSubStateLogs, lvdData.script.evts);
            viewProfile.configureTimeSlider(minTime, maxTime, latLongAltSubStateLogs, handles);

            bodyID = subStateLogs{1}(1,8);
            bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
            
            if(~isempty(handles))
                setappdata(handles.dispAxes,'CurCentralBodyId',bodyID);
            end
            
            eventsList = unique(eventsList);
            minEventNum = min(eventsList);
            maxEventNum = max(eventsList);
            
            if(minEventNum < maxEventNum)
                eventStr = ['Events ', num2str(minEventNum), ' - ', num2str(maxEventNum)];
            else
                eventStr = ['Event ', num2str(minEventNum)];
            end
            
            hDispAxisTitleLabel = handles.dispAxisTitleLabel;
            titleStr = {[bodyInfo.name, ' Orbit - ', 'Mission Segment ', curMissionSegStr, '/', totalMissionSegStr], eventStr};
            set(hDispAxisTitleLabel, 'String', titleStr);
            
            set(dAxes,'LineWidth',1);
            set(dAxes,'Box','on');
            grid(dAxes,viewProfile.gridType.gridStr);
            dAxes.GridColor = viewProfile.majorGridColor.color;
            dAxes.MinorGridColor = viewProfile.minorGridColor.color;
            dAxes.GridAlpha = viewProfile.gridTransparency;
            
            hold(dAxes,'off');
                        
            view(dAxes, 2);
            dAxes.OuterPosition = [531.0, 206.0, 418.0, 350.0];
        end
    end
end

function [childrenHGs] = plotSubStateLog(subStateLog, prevSubStateLog, showSoI, showChildBodies, showChildMarker, lvdData, celBodyData, dAxes)    
    if(isempty(subStateLog))
        childrenHGs = [];
        return;
    end
    
    bodyID = subStateLog(1,8);
    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);

    eventNum = subStateLog(1,13);
    event = lvdData.script.getEventForInd(eventNum);
    plotLineColor = event.colorLineSpec.color.color;
    plotLineStyle = event.colorLineSpec.lineSpec.linespec;
    plotLineWidth = event.colorLineSpec.lineWidth;
    plotMethodEnum = event.plotMethod;

    hold(dAxes,'on');
    
    switch plotMethodEnum
        case EventPlottingMethodEnum.PlotContinuous
            ut = [prevSubStateLog(end,1);subStateLog(1:end,1)];
            x = [prevSubStateLog(end,2);subStateLog(1:end,2)];
            y = [prevSubStateLog(end,3);subStateLog(1:end,3)];
            z = [prevSubStateLog(end,4);subStateLog(1:end,4)];
        case EventPlottingMethodEnum.SkipFirstState
            ut = subStateLog(2:end,1);
            x = subStateLog(2:end,2);
            y = subStateLog(2:end,3);
            z = subStateLog(2:end,4);
        case EventPlottingMethodEnum.DoNotPlot
            ut = [];
            x = [];
            y = [];
            z = [];
        otherwise
            error('Unknown event plotting method enum: %s', plotMethodEnum.name);
    end

    %actually plot the trajectory here
    plot2DMercatorTraj(bodyInfo, ut, x, y, z, plotLineColor, plotLineStyle, plotLineWidth, dAxes);

    childrenHGs = cell(0,4);
end

function plot2DMercatorTraj(bodyInfo, ut, x, y, z, plotLineColor, plotLineStyle, plotLineWidth, dAxes)
    %draw trajectory
    latBF = NaN(1,length(ut));
    longBF = NaN(1,length(ut));
    for(i=1:length(ut))
        rVectECI = [x(i);y(i);z(i)];
        [lat, long, ~, ~, ~, ~, ~, ~, ~] = getLatLongAltFromInertialVect(ut(i), rVectECI, bodyInfo);

        longBF(i) = rad2deg(angleNegPiToPi(long));
        latBF(i) = rad2deg(lat);
    end   
    plot(dAxes, longBF, latBF, 'Color', plotLineColor, 'LineStyle', plotLineStyle, 'LineWidth',plotLineWidth);

    xlim(dAxes, [-180 180]);
    xlabel(dAxes, 'Longitude [deg]');

    ylim(dAxes, [-90 90]);
    ylabel(dAxes, 'Latitude [deg]');

    dAxes.XTickLabelMode = 'auto';
    dAxes.YTickLabelMode = 'auto';
    dAxes.ZTickLabelMode = 'auto';
    
    grid minor;    
end