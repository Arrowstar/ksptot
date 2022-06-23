classdef Generic3DTrajectoryViewType < AbstractTrajectoryViewType
    %Inertial3DTrajectoryViewType Summary of this class goes here
    %   Detailed explanation goes here
    
    properties

    end
    
    methods
        function obj = Generic3DTrajectoryViewType()
            
        end
        
        function [hCBodySurf, childrenHGs] = plotStateLog(obj, orbitNumToPlot, lvdData, viewProfile, handles, app)
%             dAxes = app.dispAxes;
            dAxes = handles.dispAxes;
            hFig = app.ma_LvdMainGUI;
            celBodyData = lvdData.celBodyData;
            stateLog = lvdData.stateLog;
            
%             axes(dAxes);
%             cla(dAxes);
%             cla(dAxes,'reset');
            delete(dAxes.Children);
            dAxes.Color = viewProfile.backgroundColor.color;
            
            hFig.Renderer = viewProfile.renderer.renderer;
            if(viewProfile.renderer == FigureRendererEnum.OpenGL && ~isunix())
                d = opengl('data');
                if(strcmpi(d.HardwareSupportLevel,'full'))
                    opengl hardware;
                elseif(strcmpi(d.HardwareSupportLevel,'basic'))
                    opengl hardwarebasic;
                end
            end
            
            hFig.GraphicsSmoothing = 'on';
            
            if(stateLog.getNumberOfEntries() == 0)
                return;
            end
            
            viewInFrame = viewProfile.frame;
            viewCentralBody = viewInFrame.getOriginBody();
            lvdStateLogEntries = LaunchVehicleStateLogEntry.empty(1,0);
            switch viewProfile.trajEvtsViewType
                case ViewEventsTypeEnum.SoIChunk
                    entries = stateLog.getAllEntries();
%                     maStateLog = stateLog.getMAFormattedStateLogMatrix(false);

%                     chunkedStateLog = breakStateLogIntoSoIChunks(maStateLog);
                    chunkedStateLog = stateLog.breakUpStateLogBySoIChunk();
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
                        
                        elemSet = CartesianElementSet(subStateLog(:,1), subStateLog(:,2:4)', subStateLog(:,5:7)', inertialFrame);
%                         elemSet = repmat(CartesianElementSet.getDefaultElements(), [1, size(subStateLog,1)]);
%                         for(j=1:size(subStateLog,1))
%                             elemSet(j) = CartesianElementSet(subStateLog(j,1), subStateLog(j,2:4)', subStateLog(j,5:7)', inertialFrame);
%                         end
                        elemSet = convertToFrame(elemSet, viewInFrame);

                        subStateLog(:,2:4) = [elemSet.rVect]';
                        subStateLog(:,5:7) = [elemSet.vVect]';
                        
                        evtIds = [evtIds, unique(subStateLog(:,13))']; %#ok<AGROW>
                        
                        subStateLogs{i} = subStateLog;
                    end
                    
                    evtIds = unique(evtIds);
                    for(i=1:length(entries))
                        entry = entries(i);
                        
                        if(not(isempty(entry.event.getEventNum())) && ...
                           ismember(entry.event.getEventNum(), evtIds) && ...
                           entry.centralBody == bodyInfo)
                            lvdStateLogEntries(end+1) = entry; %#ok<AGROW>
                        end
                    end

                    numTotMissionSegs = size(chunkedStateLog,1);
                    
%                     curMissionSegStr = num2str(orbitNumToPlot);
%                     totalMissionSegStr = num2str(numTotMissionSegs);
                
                    if(numTotMissionSegs <= 1)
                        app.decrOrbitToPlotNum.Enable = 'off';
                        app.incrOrbitToPlotNum.Enable = 'off';
                    else
                        app.decrOrbitToPlotNum.Enable = 'on';
                        app.incrOrbitToPlotNum.Enable = 'on';
                    end
                case ViewEventsTypeEnum.All
                    entries = stateLog.getAllEntries();
                    maStateLogMatrix = stateLog.getMAFormattedStateLogMatrix(false);
                    numRows = size(maStateLogMatrix,1);
%                     subStateLogsMat = NaN(numRows, 13);
                    
                    cartesianEntry = convertToFrame(getCartesianElementSetRepresentation(entries, false),viewInFrame);
                    times = [cartesianEntry.time]';
                    rVect = [cartesianEntry.rVect]';
                    vVect = [cartesianEntry.vVect]';
                    bodyId = viewCentralBody.id + zeros(numRows,1);
                    subStateLogsMat = [times, rVect, vVect, bodyId, maStateLogMatrix(:,9:13)];
%                     for(i=1:numRows)
%                         tempMaMatrix = entries(i).getMAFormattedStateLogMatrix(false);
% 
%                         cartesianEntry = 
%                         cartesianEntry = cartesianEntry.convertToFrame(viewInFrame); 
% 
%                         subStateLogsMat(i,:) = [entries(i).time, cartesianEntry.rVect', cartesianEntry.vVect', viewCentralBody.id, maStateLogMatrix(i,9:13)];
%                     end

                    subStateLogs = {};
                    for(evtNum=1:max(subStateLogsMat(:,13)))
                        subStateLogs{evtNum} = subStateLogsMat(subStateLogsMat(:,13) == evtNum,:); %#ok<AGROW>
                    end

%                     curMissionSegStr = num2str(1);
%                     totalMissionSegStr = num2str(1);
                    
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
                    [childrenHGs] = plotSubStateLog(subStateLogs{i}, prevSubStateLog, lvdData, dAxes);
                    
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
                
                subsetLvdStateLogEntries = lvdStateLogEntries(1:entryInc:length(lvdStateLogEntries));
                subsetLvdStateLogEntries = subsetLvdStateLogEntries(:)';
                cartesianEntries = convertToFrame(getCartesianElementSetRepresentation(subsetLvdStateLogEntries), viewInFrame);
                
                rVects = [cartesianEntries.rVect];
                tVects = [];
                
                [~, ~, ~, rotMatToInertial12] = viewInFrame.getOffsetsWrtInertialOrigin([cartesianEntries.time], cartesianEntries);
                for(i=1:length(subsetLvdStateLogEntries)) %#ok<*NO4LP>
                    entry = subsetLvdStateLogEntries(i);
                    cartesianEntry = cartesianEntries(i);       
                    
                    tVect = lvd_ThrottleTask(entry, 'thrust_vector', cartesianEntry.frame);
                    
                    if(norm(tVect) > 0)                       
                        [~, ~, ~, rotMatToInertial32] = entry.centralBody.getBodyCenteredInertialFrame().getOffsetsWrtInertialOrigin(entry.time, cartesianEntry);
                        
                        tVectNew = rotMatToInertial32 * rotMatToInertial12(:,:,i)' * tVect;
                    else
                        tVectNew = [0;0;0];
                    end
                    
                    tVects = [tVects, tVectNew]; %#ok<AGROW>
                end
                
                tVects = scale .* tVects;
                
                hold(dAxes,'on');
                quiver3(dAxes, rVects(1,:),rVects(2,:),rVects(3,:), tVects(1,:),tVects(2,:),tVects(3,:), 0, 'Color',color, 'LineStyle',lineStyle);
                hold(dAxes,'off');
            end

%             lfm = LiftForceModel();
%             rVects = NaN([3, length(lvdStateLogEntries)]);
%             forceVect = NaN([3, length(lvdStateLogEntries)]);
%             for(i=1:length(lvdStateLogEntries))
%                 stateLogEntry = lvdStateLogEntries(i);
% 
%                 bodyInfo = stateLogEntry.centralBody;
%                 ut = stateLogEntry.time;
%                 rVect = stateLogEntry.position;
%                 vVect = stateLogEntry.velocity;
%                 aero = stateLogEntry.aero;
%                 mass = stateLogEntry.getTotalVehicleMass();
%                 attState = stateLogEntry.attitude;
% 
%                 rVects(:,i) = rVect;
%                 force = lfm.getForce(ut, rVect, vVect, mass, bodyInfo, aero, [], [], [], [], [], [], [], [], [], [], attState);
%                 forceVect(:,i) = 1000*force;
%             end
% 
%             hold(dAxes,'on');
%             quiver3(dAxes, rVects(1,:),rVects(2,:),rVects(3,:), forceVect(1,:),forceVect(2,:),forceVect(3,:), 0, 'Color','c', 'LineStyle','-');
%             hold(dAxes,'off');

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
                                    
            %plot central body
            [hCBodySurf, hCBodySurfXForm] = ma_initOrbPlot(hFig, dAxes, viewCentralBody);
            hCBodySurf.EdgeAlpha = viewProfile.meshEdgeAlpha; 
  
            if(viewProfile.showAtmosphere && viewCentralBody.atmohgt > 0)
                hold(dAxes,'on');
                atmoRadius = viewCentralBody.radius + viewCentralBody.atmohgt;
                [X,Y,Z] = sphere(50);
                hCBodySurf = surf(dAxes, atmoRadius*X,atmoRadius*Y,atmoRadius*Z, 'BackFaceLighting','lit', 'FaceLighting','gouraud', 'FaceColor',[223 223 223]/255, 'FaceAlpha',0.2, 'EdgeLighting','gouraud', 'LineWidth',0.1, 'EdgeColor','none');
                hold(dAxes,'off');
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
            titleStr = sprintf('%s Orbit -- %s\n%s', viewCentralBody.name, eventStr, viewInFrame.getNameStr());
            hDispAxisTitleLabel.String = titleStr;
            hDispAxisTitleLabel.TooltipString = sprintf('Frame: %s', viewInFrame.getNameStr());
            
            set(dAxes,'LineWidth',1);
            set(dAxes,'Box','on');
            grid(dAxes,viewProfile.gridType.gridStr);
            dAxes.GridColor = viewProfile.majorGridColor.color;
            dAxes.MinorGridColor = viewProfile.minorGridColor.color;
            dAxes.GridAlpha = viewProfile.gridTransparency;
%             axis(dAxes,'equal');
%             axis(dAxes,'tight');
            
%             xlabel(dAxes, '');
%             ylabel(dAxes, '');
            
            set(dAxes,'XTickLabel',[]);
            set(dAxes,'YTickLabel',[]);
            set(dAxes,'ZTickLabel',[]);
            
            hold(dAxes,'off');
            
            if(not(viewProfile.updateViewAxesLimits))
%                 setappdata(handles.ma_LvdMainGUI,'dispOrbitXLim',xlim(dAxes));
%                 setappdata(handles.ma_LvdMainGUI,'dispOrbitYLim',ylim(dAxes));
%                 setappdata(handles.ma_LvdMainGUI,'dispOrbitZLim',zlim(dAxes));
                
%                 zoom reset;
                
%                 view(dAxes,viewProfile.viewAzEl);
                
                camPos = viewProfile.viewCameraPosition;
                camTgt = viewProfile.viewCameraTarget;
                camUpVec = viewProfile.viewCameraUpVector;
                camVA = viewProfile.viewCameraViewAngle;
                if(not(any(isnan(camPos))))
                    dAxes.CameraPosition = camPos;
                end
                
                if(not(any(isnan(camTgt))))
                    dAxes.CameraTarget = camTgt;
                end
                
                if(not(any(isnan(camUpVec))))
                    dAxes.CameraUpVector = camUpVec;
                end
                
                if(not(any(isnan(camVA))))
                    dAxes.CameraViewAngle = camVA;
                end
                
%                 if(any(isnan(viewProfile.viewZoomAxLims)))
%                     viewProfile.viewZoomAxLims = [xlim(dAxes);
%                                                   ylim(dAxes);
%                                                   zlim(dAxes)];
%                 else
%                     dAxes.XLim = viewProfile.viewZoomAxLims(1,:);
%                     dAxes.YLim = viewProfile.viewZoomAxLims(2,:);
%                     dAxes.ZLim = viewProfile.viewZoomAxLims(3,:);
%                 end
%                 
            else
                cameratoolbar('ResetCamera');
                view(dAxes, 3);
            end
                        
            vehPosVelData = LaunchVehicleViewProfile.createVehPosVelData(subStateLogs, lvdData.script.evts, viewInFrame);
            vehAttData = LaunchVehicleViewProfile.createVehAttitudeData(vehPosVelData, lvdStateLogEntries, lvdData.script.evts, viewInFrame);
            
            hold(dAxes,'on');
            viewProfile.createBodyMarkerData(dAxes, subStateLogs, viewInFrame, showSoI, viewProfile.meshEdgeAlpha, lvdData.script.evts);           
            viewProfile.createTrajectoryMarkerData(subStateLogs, lvdData.script.evts);
            viewProfile.createBodyAxesData(vehPosVelData, vehAttData); %lvdStateLogEntries, lvdData.script.evts, viewInFrame
            viewProfile.createSunLightSrc(dAxes, viewInFrame);
            viewProfile.createGroundObjMarkerData(dAxes, lvdStateLogEntries, vehPosVelData, lvdData.script.evts, viewInFrame, celBodyData);
            viewProfile.createCentralBodyData(viewCentralBody, hCBodySurfXForm, viewInFrame);
            viewProfile.createPointData(viewInFrame, subStateLogs, lvdData.script.evts);           
            viewProfile.createVectorData(viewInFrame, subStateLogs, lvdData.script.evts);
            viewProfile.createRefFrameData(viewInFrame, subStateLogs, lvdData.script.evts);
            viewProfile.createAngleData(viewInFrame, subStateLogs, lvdData.script.evts);
            viewProfile.createPlaneData(viewInFrame, subStateLogs, lvdData.script.evts);           
            viewProfile.createSensorData(lvdStateLogEntries, vehPosVelData, vehAttData, viewInFrame);
            viewProfile.createSensorTargetData(viewInFrame);
            
            viewProfile.configureTimeSlider(minTime, maxTime, subStateLogs, handles, app);
            hold(dAxes,'off');

            switch viewProfile.projType
                case ViewProjectionTypeEnum.Orthographic
                    camproj(dAxes, 'orthographic');
    
                case ViewProjectionTypeEnum.Perspective
                    camproj(dAxes, 'perspective');

                otherwise
                    error('Unknown projection type: %s', viewProfile.projType.name);

            end
        end
    end
end

function [childrenHGs] = plotSubStateLog(subStateLog, prevSubStateLog, lvdData, dAxes)    
    if(isempty(subStateLog))
        childrenHGs = [];
        return;
    end
    
%     bodyID = subStateLog(1,8);
%     bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);

    eventNum = subStateLog(1,13);
    event = lvdData.script.getEventForInd(eventNum);
    if(isempty(event))
        childrenHGs = [];
        return;
    end
    
    plotLineColor = event.colorLineSpec.color.color;
    plotLineStyle = event.colorLineSpec.lineSpec.linespec;
    plotLineWidth = event.colorLineSpec.lineWidth;
    plotMarkerType = event.colorLineSpec.markerSpec.shape;
    plotMarkerSize = event.colorLineSpec.markerSize;
    plotMethodEnum = event.plotMethod;

    hold(dAxes,'on');
    
    switch plotMethodEnum
        case EventPlottingMethodEnum.PlotContinuous
            t = [prevSubStateLog(end,1);subStateLog(1:end,1)];
            x = [prevSubStateLog(end,2);subStateLog(1:end,2)];
            y = [prevSubStateLog(end,3);subStateLog(1:end,3)];
            z = [prevSubStateLog(end,4);subStateLog(1:end,4)];

            [~,I] = sort(t);
            x = x(I);
            y = y(I);
            z = z(I);

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

    plot3(dAxes, x, y, z, 'Color', plotLineColor, 'LineStyle', plotLineStyle, 'LineWidth',plotLineWidth, 'Marker',plotMarkerType, 'MarkerSize',plotMarkerSize, 'MarkerEdgeColor','none', 'MarkerFaceColor',plotLineColor);   
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