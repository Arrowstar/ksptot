function [hCBodySurf, childrenHGs] = plotStateLog(stateLog, handles, showSoI, showChildBodies, showChildMarker, showOtherSC, orbitNumToPlot, hDispAxisTitleLabel, celBodyData, dAxes, hFig)
%plotStateLog Summary of this function goes here
%   Detailed explanation goes here
    if(~exist('dAxes','var'))
        dAxes = gca;
    end
    if(~exist('hFig','var'))
        hFig = gcf;
    end
        
    basePlotColors = ['r','m','y','g','c','b'];
    numCopies = max(ceil(unique(stateLog(:,13)) / length(basePlotColors)) + 1);
    plotColors = basePlotColors;
    for(i=1:numCopies)
        plotColors = [plotColors,basePlotColors]; %#ok<AGROW>
    end

    chunkedStateLog = breakStateLogIntoSoIChunks(stateLog);
    if(orbitNumToPlot > size(chunkedStateLog,1))
        orbitNumToPlot = size(chunkedStateLog,1);
        set(dAxes,'UserData',orbitNumToPlot);
    end
    subStateLogs = chunkedStateLog(orbitNumToPlot,:);
    eventsList = [];
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    otherSC = maData.spacecraft.otherSC;
    for(i=1:length(subStateLogs))
        if(~isempty(subStateLogs{i}))
            eventsList = [eventsList;unique(subStateLogs{i}(:,13))]; %#ok<AGROW>
        end
        [childrenHGs] = plotSubStateLog(subStateLogs{i}, showSoI, showChildBodies, showChildMarker, showOtherSC, otherSC, plotColors, celBodyData, dAxes, hFig);
    end
    
    bodyID = subStateLogs{1}(1,8);
    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    hCBodySurf = ma_initOrbPlot(hFig, dAxes, bodyInfo);
    
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
    axis(dAxes,'equal');
    hold(dAxes,'off');
    
    if(~isempty(handles))
        setappdata(handles.ma_MainGUI,'dispOrbitXLim',xlim(dAxes));
        setappdata(handles.ma_MainGUI,'dispOrbitYLim',ylim(dAxes));
        setappdata(handles.ma_MainGUI,'dispOrbitZLim',zlim(dAxes));
        applyZoomLevel(handles.ma_MainGUI);
    end
end

function [childrenHGs] = plotSubStateLog(subStateLog, showSoI, showChildBodies, showChildMarker, showOtherSC, otherSCs, plotColors, celBodyData, dAxes, hFig)    
    if(isempty(subStateLog))
        childrenHGs = [];
        return;
    end
    
    bodyID = subStateLog(1,8);
    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);

    hold(dAxes,'on');
	plot3(dAxes, subStateLog(1:end,2), subStateLog(1:end,3), subStateLog(1:end,4), plotColors(subStateLog(1,13)), 'LineWidth',1.5);
    
    if(showSoI && ~isempty(getParentBodyInfo(bodyInfo, celBodyData)))
        r = getSOIRadius(bodyInfo, getParentBodyInfo(bodyInfo, celBodyData));
        plot(dAxes,r*sin(0:0.01:2*pi),r*cos(0:0.01:2*pi), 'k--','LineWidth',1.5);
    end
    
    childrenHGs = cell(0,4);
    if(showChildBodies)
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
            childrenHGs(end+1,:) = {child, hBody1, hBody2, hOrbit};
        end
    end
    
    if(showOtherSC)
        for(i=1:length(otherSCs))
            otherSC = otherSCs{i};
            posOffset = [0,0,0]';
            validBodyID = bodyID;
            ut = otherSC.epoch;
            plotLocOfOtherSC(dAxes, otherSC, validBodyID, ut, posOffset, bodyInfo, true, false);
        end
    end
end