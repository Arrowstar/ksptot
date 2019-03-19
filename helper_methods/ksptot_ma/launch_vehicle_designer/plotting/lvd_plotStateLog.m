function [hCBodySurf, childrenHGs] = lvd_plotStateLog(stateLog, handles, showSoI, showChildBodies, showChildMarker, showOtherSC, orbitNumToPlot, hDispAxisTitleLabel, orbitPlotType, lvdData, celBodyData, dAxes, hFig)
%lvd_plotStateLog Summary of this function goes here
%   Detailed explanation goes here
    if(~exist('dAxes','var'))
        dAxes = gca;
    end
    if(~exist('hFig','var'))
        hFig = gcf;
    end
    
    if(isempty(stateLog))
        return;
    end
        
    chunkedStateLog = breakStateLogIntoSoIChunks(stateLog);
    if(orbitNumToPlot > size(chunkedStateLog,1))
        orbitNumToPlot = size(chunkedStateLog,1);
        set(dAxes,'UserData',orbitNumToPlot);
    end
    subStateLogs = chunkedStateLog(orbitNumToPlot,:);
    eventsList = [];
%     otherSC = maData.spacecraft.otherSC;
    otherSC = {};
    
    if(strcmpi(orbitPlotType,'2DMercador'))
        delete(allchild(dAxes));
        cla(dAxes, 'reset');
        view(2);
        set(dAxes,'UserData',orbitNumToPlot);
    end
    
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
            [childrenHGs] = plotSubStateLog(subStateLogs{i}, prevSubStateLog, showSoI, showChildBodies, showChildMarker, showOtherSC, otherSC, orbitPlotType, lvdData, celBodyData, dAxes);
        end
    end
    
    bodyID = subStateLogs{1}(1,8);
    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    
    if(strcmpi(orbitPlotType,'3DInertial') || strcmpi(orbitPlotType,'3DBodyFixed'))
        grid off;
        hCBodySurf = ma_initOrbPlot(hFig, dAxes, bodyInfo);
    end
    
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
    
    bodyID = subStateLogs{1}(1,8);
    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    if(~isempty(hDispAxisTitleLabel))
        set(hDispAxisTitleLabel, 'String', {[bodyInfo.name, ' Orbit - ', 'Mission Segment ', num2str(orbitNumToPlot), '/', num2str(size(chunkedStateLog,1))], eventStr});
    end
    
    set(dAxes,'LineWidth',1);
    set(dAxes,'Box','on');
    grid(dAxes,'on');
    if(strcmpi(orbitPlotType,'3DInertial') || strcmpi(orbitPlotType,'3DBodyFixed'))
        axis(dAxes,'equal');
    elseif(strcmpi(orbitPlotType,'2DMercador'))
        %nothing
    else
        error('Unknown plot type: %s', orbitPlotType);
    end
    hold(dAxes,'off');
    
    if(~isempty(handles))
        setappdata(handles.ma_LvdMainGUI,'dispOrbitXLim',xlim(dAxes));
        setappdata(handles.ma_LvdMainGUI,'dispOrbitYLim',ylim(dAxes));
        setappdata(handles.ma_LvdMainGUI,'dispOrbitZLim',zlim(dAxes));
        applyZoomLevel(handles.ma_LvdMainGUI, handles, celBodyData);
    end
end

function [childrenHGs] = plotSubStateLog(subStateLog, prevSubStateLog, showSoI, showChildBodies, showChildMarker, showOtherSC, otherSCs, orbitPlotType, lvdData, celBodyData, dAxes)    
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

    hold(dAxes,'on');
    
    ut = [prevSubStateLog(end,1);subStateLog(1:end,1)];
    x = [prevSubStateLog(end,2);subStateLog(1:end,2)];
    y = [prevSubStateLog(end,3);subStateLog(1:end,3)];
    z = [prevSubStateLog(end,4);subStateLog(1:end,4)];
    switch orbitPlotType
        case '3DInertial'
            plot3(dAxes, x, y, z, 'Color', plotLineColor, 'LineStyle', plotLineStyle, 'LineWidth',plotLineWidth);
            xlabel('');
            ylabel('');
            
        case '3DBodyFixed'           
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
                xToPlot = [xToPlot, 0, xunit(i), NaN];
                yToPlot = [yToPlot, 0, yunit(i), NaN];
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
                xToPlot = [xToPlot, 0, xunit(i), NaN];
                yToPlot = [yToPlot, 0, yunit(i), NaN];
                zToPlot = [zToPlot, 0, zunit(i), NaN];
            end
            
            plot3(dAxes, xToPlot, yToPlot, zToPlot, 'k');
            
            xunitTxt = rTxt * cosd(th);
            yunitTxt = zeros(size(th));
            zunitTxt = rTxt * sind(th);
            
            for(i=1:length(xunitTxt))
                text(dAxes, xunitTxt(i),yunitTxt(i),zunitTxt(i), sprintf('%.0f%s', th(i), char(176)));
            end
            
            %draw trajectory
            xBF = NaN(1,length(ut));
            yBF = NaN(1,length(ut));
            zBF = NaN(1,length(ut));
            for(i=1:length(ut))
                rVectECI = [x(i);y(i);z(i)];
                [rVectECEF, ~, ~] = getFixedFrameVectFromInertialVect(ut(i), rVectECI, bodyInfo);
                
                xBF(i) = rVectECEF(1);
                yBF(i) = rVectECEF(2);
                zBF(i) = rVectECEF(3);
            end        
            
            plot3(dAxes, xBF, yBF, zBF, 'Color', plotLineColor, 'LineStyle', plotLineStyle, 'LineWidth',plotLineWidth);
            xlabel('');
            ylabel('');
            
        case '2DMercador'
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
            
            xlim([-180 180]);
            xlabel('Longitude [deg]');
            
            ylim([-90 90]);
            ylabel('Latitude [deg]');
            
            grid minor;
            
        otherwise
            error('Unknown plot type: %s', orbitPlotType);        
    end

    childrenHGs = cell(0,4);
    if(showSoI && ~isempty(bodyInfo.getParBodyInfo(celBodyData)) && ...
       (strcmpi(orbitPlotType,'3DInertial') || strcmpi(orbitPlotType,'3DBodyFixed')))
        
        r = getSOIRadius(bodyInfo, bodyInfo.getParBodyInfo(celBodyData));
        plot(dAxes,r*sin(0:0.01:2*pi),r*cos(0:0.01:2*pi), 'k--','LineWidth',1.5);
    end
    
	if(showChildBodies && (strcmpi(orbitPlotType,'3DInertial') || strcmpi(orbitPlotType,'3DBodyFixed')))
        [children] = getChildrenOfParentInfo(celBodyData, bodyInfo.name);

        time1 = subStateLog(1,1);
        time2 = subStateLog(end,1);
        for(childA = children) %#ok<*NO4LP>
            child = childA{1};            

            hOrbit = plotBodyOrbit(child, 'k', bodyInfo.gm, true);

            hBody1 = ma_plotChildBody(child, child, time1, bodyInfo.gm, dAxes, showSoI, showChildMarker, celBodyData);
            if(time1~=time2)
                hBody2 = ma_plotChildBody(child, child, time2, bodyInfo.gm, dAxes, showSoI, showChildMarker, celBodyData);
            else
                hBody2 = [];
            end
            childrenHGs(end+1,:) = {child, hBody1, hBody2, hOrbit}; %#ok<AGROW>
        end
	end
    

    
%     if(showOtherSC)
%         for(i=1:length(otherSCs))
%             otherSC = otherSCs{i};
%             posOffset = [0,0,0]';
%             validBodyID = bodyID;
%             ut = otherSC.epoch;
%             plotLocOfOtherSC(dAxes, otherSC, validBodyID, ut, posOffset, bodyInfo, true, false);
%         end
%     end
end