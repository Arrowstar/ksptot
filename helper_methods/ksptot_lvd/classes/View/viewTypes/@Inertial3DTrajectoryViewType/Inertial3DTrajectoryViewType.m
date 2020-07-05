classdef Inertial3DTrajectoryViewType < AbstractTrajectoryViewType
    %Inertial3DTrajectoryViewType Summary of this class goes here
    %   Detailed explanation goes here
    
    properties

    end
    
    methods
        function obj = Inertial3DTrajectoryViewType()
            
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

                    curMissionSegStr = num2str(orbitNumToPlot);
                    totalMissionSegStr = num2str(size(chunkedStateLog,1));
                    
                    bodyID = subStateLogs{1}(1,8);
                    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
                    viewInFrame = bodyInfo.getBodyCenteredInertialFrame();
                
                case ViewEventsTypeEnum.All
                    viewCentralBody = viewProfile.viewCentralBody;
                    viewInFrame = viewCentralBody.getBodyCenteredInertialFrame();

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
                    [childrenHGs] = plotSubStateLog(subStateLogs{i}, prevSubStateLog, showSoI, lvdData, celBodyData, dAxes);
                    
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
            if(dAxes.Parent == hFig)
                dAxes.Position = [531.0, 206.0, 418.0, 350.0];
            end
        end
    end
end

function [childrenHGs] = plotSubStateLog(subStateLog, prevSubStateLog, showSoI, lvdData, celBodyData, dAxes)    
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

    if(showSoI && ~isempty(bodyInfo.getParBodyInfo(celBodyData)))
        r = getSOIRadius(bodyInfo, bodyInfo.getParBodyInfo(celBodyData));
        
        x = r*sin(0:0.01:2*pi);
        y = r*cos(0:0.01:2*pi);
        z = zeros(size(x));
        plot3(dAxes, x, y, z, 'k--','LineWidth',1.5);
        plot3(dAxes, y, z, x, 'k--','LineWidth',1.5);
        plot3(dAxes, z, x, y, 'k--','LineWidth',1.5);
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