classdef BodyFixed3DTrajectoryViewType < AbstractTrajectoryViewType
    %BodyFixed3DTrajectoryViewType Summary of this class goes here
    %   Detailed explanation goes here
    
    properties

    end
    
    methods
        function obj = BodyFixed3DTrajectoryViewType()
            
        end
        
        function [hCBodySurf, childrenHGs] = plotStateLog(obj, orbitNumToPlot, lvdData, viewProfile, handles)
            dAxes = handles.dispAxes;
            hFig = handles.ma_LvdMainGUI;
            celBodyData = lvdData.celBodyData;
            stateLog = lvdData.stateLog;
            
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
                    
                    for(i=1:length(subStateLogs))
                        subStateLog = subStateLogs{i};

                        times = subStateLog(:,1);
                        rVectECI = subStateLog(:,2:4);
                        bodyInfo = getBodyInfoByNumber(subStateLog(1,8), celBodyData);
                        [rVectECEF, ~, ~] = getFixedFrameVectFromInertialVect(times, rVectECI', bodyInfo);
                        
                        subStateLog(:,2:4) = rVectECEF';
                        subStateLogs{i} = subStateLog;
                    end

                    curMissionSegStr = num2str(orbitNumToPlot);
                    totalMissionSegStr = num2str(size(chunkedStateLog,1));
                    
                    bodyID = subStateLogs{1}(1,8);
                    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
                    viewInFrame = bodyInfo.getBodyFixedFrame();
                
                case ViewEventsTypeEnum.All
                    viewCentralBody = viewProfile.viewCentralBody;
                    viewInFrame = viewCentralBody.getBodyFixedFrame();

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
                    showSoI = viewProfile.showSoIRadius;
                    showLongLatAnnotations = viewProfile.showLongLatAnnotations;
                    [childrenHGs] = plotSubStateLog(subStateLogs{i}, prevSubStateLog, showSoI, showLongLatAnnotations, lvdData, celBodyData, dAxes);
                    
                    minTime = min([minTime, min(subStateLogs{i}(:,1))]);
                    maxTime = max([maxTime, max(subStateLogs{i}(:,1))]);
                end
            end
            
            viewProfile.createBodyMarkerData(dAxes, subStateLogs, viewInFrame);
            viewProfile.createTrajectoryMarkerData(subStateLogs, lvdData.script.evts);
            viewProfile.configureTimeSlider(minTime, maxTime, subStateLogs, handles);
            
            bodyID = subStateLogs{1}(1,8);
            bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
            
            grid off;
            hCBodySurf = ma_initOrbPlot(hFig, dAxes, bodyInfo);
            
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
            axis(dAxes,'equal');
            
            hold(dAxes,'off');
            
            setappdata(handles.ma_LvdMainGUI,'dispOrbitXLim',xlim(dAxes));
            setappdata(handles.ma_LvdMainGUI,'dispOrbitYLim',ylim(dAxes));
            setappdata(handles.ma_LvdMainGUI,'dispOrbitZLim',zlim(dAxes));
            applyZoomLevel(handles.ma_LvdMainGUI, handles, celBodyData);
            
            view(dAxes,viewProfile.viewAzEl);
            handles.dispAxes.Position = [531.0, 206.0, 418.0, 350.0];
        end
    end
end

function [childrenHGs] = plotSubStateLog(subStateLog, prevSubStateLog, showSoI, showLongLatAnnotations, lvdData, celBodyData, dAxes)    
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
    plotBodyFixedTrajectory(bodyInfo, ut, x, y, z, plotLineColor, plotLineStyle, plotLineWidth, showLongLatAnnotations, dAxes);

    if(showSoI && ~isempty(bodyInfo.getParBodyInfo(celBodyData)))
        r = getSOIRadius(bodyInfo, bodyInfo.getParBodyInfo(celBodyData));
        plot(dAxes,r*sin(0:0.01:2*pi),r*cos(0:0.01:2*pi), 'k--','LineWidth',1.5);
    end
    
    childrenHGs = cell(0,4);
% 	if(showChildBodies)
%         [children] = getChildrenOfParentInfo(celBodyData, bodyInfo.name);
% 
%         time1 = subStateLog(1,1);
%         time2 = subStateLog(end,1);
%         for(childA = children) %#ok<*NO4LP>
%             child = childA{1};            
% 
%             hOrbit = plotBodyOrbit(child, 'k', bodyInfo.gm, true);
% 
%             hBody1 = ma_plotChildBody(child, child, time1, bodyInfo.gm, dAxes, showSoI, showChildMarker, celBodyData);
%             if(time1~=time2)
%                 hBody2 = ma_plotChildBody(child, child, time2, bodyInfo.gm, dAxes, showSoI, showChildMarker, celBodyData);
%             else
%                 hBody2 = [];
%             end
%             childrenHGs(end+1,:) = {child, hBody1, hBody2, hOrbit}; %#ok<AGROW>
%         end
% 	end
end

function plotBodyFixedTrajectory(bodyInfo, ut, xBF, yBF, zBF, plotLineColor, plotLineStyle, plotLineWidth, showLongLatAnnotations, dAxes)
    if(showLongLatAnnotations)
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

    %draw trajectory
%     xBF = NaN(1,length(ut));
%     yBF = NaN(1,length(ut));
%     zBF = NaN(1,length(ut));
%     for(i=1:length(ut))
%         rVectECI = [xBF(i);yBF(i);zBF(i)];
%         [rVectECEF, ~, ~] = getFixedFrameVectFromInertialVect(ut(i), rVectECI, bodyInfo);
% 
%         xBF(i) = rVectECEF(1);
%         yBF(i) = rVectECEF(2);
%         zBF(i) = rVectECEF(3);
%     end        

    plot3(dAxes, xBF, yBF, zBF, 'Color', plotLineColor, 'LineStyle', plotLineStyle, 'LineWidth',plotLineWidth);
    xlabel('');
    ylabel('');  
end