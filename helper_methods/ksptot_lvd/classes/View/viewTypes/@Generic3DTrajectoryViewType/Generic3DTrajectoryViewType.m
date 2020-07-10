classdef Generic3DTrajectoryViewType < AbstractTrajectoryViewType
    %Inertial3DTrajectoryViewType Summary of this class goes here
    %   Detailed explanation goes here
    
    properties

    end
    
    methods
        function obj = Generic3DTrajectoryViewType()
            
        end
        
        function [hCBodySurf, childrenHGs] = plotStateLog(obj, orbitNumToPlot, lvdData, viewProfile, handles)
            dAxes = handles.dispAxes;
            hFig = handles.ma_LvdMainGUI;
            celBodyData = lvdData.celBodyData;
            stateLog = lvdData.stateLog;
            
            axes(dAxes);
            cla(dAxes);
            cla(dAxes,'reset')
            
            if(stateLog.getNumberOfEntries() == 0)
                return;
            end
            
            viewInFrame = viewProfile.frame;
            viewCentralBody = viewInFrame.getOriginBody();
            lvdStateLogEntries = LaunchVehicleStateLogEntry.empty(1,0);
            switch viewProfile.trajEvtsViewType
                case ViewEventsTypeEnum.SoIChunk
                    entries = stateLog.getAllEntries();
                    maStateLog = stateLog.getMAFormattedStateLogMatrix();

                    chunkedStateLog = breakStateLogIntoSoIChunks(maStateLog);
                    if(orbitNumToPlot > size(chunkedStateLog,1))
                        orbitNumToPlot = size(chunkedStateLog,1);
                        set(dAxes,'UserData',orbitNumToPlot);
                    end
                    subStateLogs = chunkedStateLog(orbitNumToPlot,:);
                    
                    bodyId = subStateLogs{1}(1,8);
                    bodyInfo = celBodyData.getBodyInfoById(bodyId);
                    evtIds = [];
                    for(i=1:length(subStateLogs))
                        subStateLog = subStateLogs{i};
                        
                        if(isempty(subStateLog))
                            continue;
                        end
                        
                        bodyId = subStateLog(1,8);
                        bodyInfo = celBodyData.getBodyInfoById(bodyId);
                        inertialFrame = bodyInfo.getBodyCenteredInertialFrame();
                        for(j=1:size(subStateLog,1))
                            elemSet = CartesianElementSet(subStateLog(j,1), subStateLog(j,2:4)', subStateLog(5:7)', inertialFrame);
                            elemSet = elemSet.convertToFrame(viewInFrame);
                            
                            subStateLog(j,2:4) = elemSet.rVect';
                            subStateLog(j,5:7) = elemSet.vVect';
                        end
                        evtIds = [evtIds, unique(subStateLog(:,13))']; %#ok<AGROW>
                        
                        subStateLogs{i} = subStateLog;
                    end
                    
                    evtIds = unique(evtIds);
                    for(i=1:length(entries))
                        entry = entries(i);
                        
                        if(ismember(entry.event.getEventNum(), evtIds) && ...
                           entry.centralBody == bodyInfo)
                            lvdStateLogEntries(end+1) = entry;
                        end
                    end

                    curMissionSegStr = num2str(orbitNumToPlot);
                    totalMissionSegStr = num2str(size(chunkedStateLog,1));
                
                case ViewEventsTypeEnum.All
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
                    
                    lvdStateLogEntries = entries;
                otherwise
                    error('Unknown trajectory view type when plotting trajectory: %s', viewProfile.frame.name);
            end
                       
            eventsList = [];
            minTime = Inf;
            maxTime = -Inf;
            for(i=1:length(subStateLogs))
                if(~isempty(subStateLogs{i}))
                    eventsList = [eventsList;unique(subStateLogs{i}(:,13))]; %#ok<AGROW>
                end
                if(i>1)
                    prevSubStateLog = subStateLogs{i-1};
                else
                    prevSubStateLog = NaN(1,size(subStateLogs{i},2));
                end

                if(size(subStateLogs{i},1)>1)
                    [childrenHGs] = plotSubStateLog(subStateLogs{i}, prevSubStateLog, lvdData, celBodyData, dAxes);
                    
                    minTime = min([minTime, min(subStateLogs{i}(:,1))]);
                    maxTime = max([maxTime, max(subStateLogs{i}(:,1))]);
                end
            end
                       
            if(viewInFrame.typeEnum == ReferenceFrameEnum.BodyFixedRotating && ...
               viewProfile.showLongLatAnnotations)
                plotBodyFixedGrid(dAxes, viewCentralBody);
            end
            
            showSoI = viewProfile.showSoIRadius;
            
            if(viewProfile.showThrustVectors)
                entryInc = viewProfile.thrustVectEntryIncr;
                scale = viewProfile.thrustVectScale;
                color = viewProfile.thrustVectColor.color;
                lineStyle = viewProfile.thrustVectLineType.linespec;
                
                rVects = [];
                tVects = [];
                for(i=1:entryInc:length(lvdStateLogEntries))
                    entry = lvdStateLogEntries(i);
                    
                    cartesianEntry = entry.getCartesianElementSetRepresentation();                   
                    cartesianEntry = cartesianEntry.convertToFrame(viewInFrame); 
                    
                    rVects = [rVects, cartesianEntry.rVect]; %#ok<AGROW>
                                        
                    tX = lvd_ThrottleTask(entry, 'thrust_x');
                    tY = lvd_ThrottleTask(entry, 'thrust_y');
                    tZ = lvd_ThrottleTask(entry, 'thrust_z');
                    tVect = [tX;tY;tZ];
                    
                    if(norm(tVect) > 0)                       
                        [~, ~, ~, rotMatToInertial12] = viewInFrame.getOffsetsWrtInertialOrigin(entry.time);
                        [~, ~, ~, rotMatToInertial32] = entry.centralBody.getBodyCenteredInertialFrame().getOffsetsWrtInertialOrigin(entry.time);
                        
                        tVectNew = rotMatToInertial32 * rotMatToInertial12' * tVect;
                    else
                        tVectNew = [0;0;0];
                    end
                    
                    tVects = [tVects, tVectNew]; %#ok<AGROW>
                end
                
                hold(dAxes,'on');
                quiver3(dAxes, rVects(1,:),rVects(2,:),rVects(3,:), tVects(1,:),tVects(2,:),tVects(3,:), scale, 'Color',color, 'LineStyle',lineStyle);
                hold(dAxes,'off');
            end
            
            if(showSoI && ~isempty(viewCentralBody.getParBodyInfo(celBodyData)))
                hold(dAxes,'on');
                
                r = getSOIRadius(viewCentralBody, viewCentralBody.getParBodyInfo(celBodyData));

                x = r*sin(0:0.01:2*pi);
                y = r*cos(0:0.01:2*pi);
                z = zeros(size(x));
                plot3(dAxes, x, y, z, 'k--','LineWidth',0.5);
                plot3(dAxes, y, z, x, 'k--','LineWidth',0.5);
                plot3(dAxes, z, x, y, 'k--','LineWidth',0.5);
                
                hold(dAxes,'off');
            end
                       
            if(viewProfile.dispXAxis || viewProfile.dispYAxis || viewProfile.dispZAxis)
                axisLength = 2*viewCentralBody.radius;
                
                hold(dAxes,'on');
                if(viewProfile.dispXAxis)
                    quiver3(dAxes, 0,0,0, axisLength,0,0, 'r', 'LineWidth',2);
                end
                
                if(viewProfile.dispYAxis)
                    quiver3(dAxes, 0,0,0, 0,axisLength,0, 'g', 'LineWidth',2);
                end
                
                if(viewProfile.dispZAxis)
                    quiver3(dAxes, 0,0,0, 0,0,axisLength, 'b', 'LineWidth',2);
                end
                hold(dAxes,'off');
            end
            
            bodyID = subStateLogs{1}(1,8);
                        
            hCBodySurf = ma_initOrbPlot(hFig, dAxes, viewCentralBody);
            
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
            titleStr = {[viewCentralBody.name, ' Orbit - ', 'Mission Segment ', curMissionSegStr, '/', totalMissionSegStr], eventStr};
            set(hDispAxisTitleLabel, 'String', titleStr);
            hDispAxisTitleLabel.TooltipString = sprintf('Frame: %s', viewInFrame.getNameStr());
            
            set(dAxes,'LineWidth',1);
            set(dAxes,'Box','on');
            grid(dAxes,viewProfile.gridType.gridStr);
            dAxes.GridColor = viewProfile.majorGridColor.color;
            dAxes.MinorGridColor = viewProfile.minorGridColor.color;
            dAxes.GridAlpha = viewProfile.gridTransparency;
            axis(dAxes,'equal');
            
            hold(dAxes,'off');
            
            setappdata(handles.ma_LvdMainGUI,'dispOrbitXLim',xlim(dAxes));
            setappdata(handles.ma_LvdMainGUI,'dispOrbitYLim',ylim(dAxes));
            setappdata(handles.ma_LvdMainGUI,'dispOrbitZLim',zlim(dAxes));
            zoom reset;
%             applyZoomLevel(handles.ma_LvdMainGUI, handles, celBodyData);
            
            view(dAxes,viewProfile.viewAzEl);
            if(any(isnan(viewProfile.viewZoomAxLims)))
                viewProfile.viewZoomAxLims = [xlim(dAxes);
                                              ylim(dAxes);
                                              zlim(dAxes)];
            else
                dAxes.XLim = viewProfile.viewZoomAxLims(1,:);
                dAxes.YLim = viewProfile.viewZoomAxLims(2,:);
                dAxes.ZLim = viewProfile.viewZoomAxLims(3,:);
            end

            
            if(dAxes.Parent == hFig)
                dAxes.Position = [531.0, 206.0, 418.0, 350.0];
            end
            
            hold(dAxes,'on');
            viewProfile.createBodyMarkerData(dAxes, subStateLogs, viewInFrame, showSoI);
            viewProfile.createTrajectoryMarkerData(subStateLogs, lvdData.script.evts);
            viewProfile.configureTimeSlider(minTime, maxTime, subStateLogs, handles);
            hold(dAxes,'off');
        end
    end
end

function [childrenHGs] = plotSubStateLog(subStateLog, prevSubStateLog, lvdData, celBodyData, dAxes)    
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
            x = [prevSubStateLog(end,2);subStateLog(1:end,2)];
            y = [prevSubStateLog(end,3);subStateLog(1:end,3)];
            z = [prevSubStateLog(end,4);subStateLog(1:end,4)];
        case EventPlottingMethodEnum.SkipFirstState
            x = subStateLog(2:end,2);
            y = subStateLog(2:end,3);
            z = subStateLog(2:end,4);
        case EventPlottingMethodEnum.DoNotPlot
            x = [];
            y = [];
            z = [];
        otherwise
            error('Unknown event plotting method enum: %s', plotMethodEnum.name);
    end

    plot3(dAxes, x, y, z, 'Color', plotLineColor, 'LineStyle', plotLineStyle, 'LineWidth',plotLineWidth);
    xlabel('');
    ylabel('');
    
    childrenHGs = cell(0,4);
end

function plotBodyFixedGrid(dAxes, bodyInfo)
    r = 1.2*bodyInfo.radius;
    rTxt = 1.3*bodyInfo.radius;

    %draw longitude circle and text
    th = linspace(0, 2*pi, 100);
    xunit = r * cos(th);
    yunit = r * sin(th);
    patch(dAxes, 'XData',xunit,'YData',yunit, 'FaceColor', 'k', 'FaceAlpha',0.15);

    th = linspace(0,2*pi - (1/12)*2*pi, 12);
    xunit = r * cos(th);
    yunit = r * sin(th);

    xToPlot = [];
    yToPlot = [];
    for(i=1:length(th))
        xToPlot = [xToPlot, 0, xunit(i), NaN]; %#ok<AGROW>
        yToPlot = [yToPlot, 0, yunit(i), NaN]; %#ok<AGROW>
    end

    plot(dAxes, xToPlot, yToPlot, 'k');

    xunitTxt = rTxt * cos(th);
    yunitTxt = rTxt * sin(th);

    for(i=1:length(xunitTxt))
        text(dAxes, xunitTxt(i),yunitTxt(i),sprintf('%.0f%s', rad2deg(th(i)), char(176)));
    end

    %draw latitude circle and text
    th = linspace(-pi/2, pi/2, 100);
    xunit = r * cos(th);
    yunit = zeros(size(th));
    zunit = r * sin(th);
    patch(dAxes, 'XData',xunit,'YData',yunit,'ZData',zunit, 'FaceColor', 'k', 'FaceAlpha',0.15);

    th = rad2deg(linspace(-pi/2, pi/2, 7));
    xunit = r * cosd(th);
    yunit = zeros(size(th));
    zunit = r * sind(th);

    xToPlot = [];
    yToPlot = [];
    zToPlot = [];
    for(i=1:length(th))
        xToPlot = [xToPlot, 0, xunit(i), NaN]; %#ok<AGROW>
        yToPlot = [yToPlot, 0, yunit(i), NaN]; %#ok<AGROW>
        zToPlot = [zToPlot, 0, zunit(i), NaN]; %#ok<AGROW>
    end

    plot3(dAxes, xToPlot, yToPlot, zToPlot, 'k');

    xunitTxt = rTxt * cosd(th);
    yunitTxt = zeros(size(th));
    zunitTxt = rTxt * sind(th);

    for(i=1:length(xunitTxt))
        text(dAxes, xunitTxt(i),yunitTxt(i),zunitTxt(i), sprintf('%.0f%s', th(i), char(176)));
    end
end