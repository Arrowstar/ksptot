function [hCBodySurf, childrenHGs] = lvd_plotStateLog(stateLog, handles, showSoI, showChildBodies, showChildMarker, showOtherSC, orbitNumToPlot, hDispAxisTitleLabel, maData, lvdData, celBodyData, dAxes, hFig)
%plotStateLog Summary of this function goes here
%   Detailed explanation goes here
    if(~exist('dAxes','var'))
        dAxes = gca;
    end
    if(~exist('hFig','var'))
        hFig = gcf;
    end
        
    chunkedStateLog = breakStateLogIntoSoIChunks(stateLog);
    if(orbitNumToPlot > size(chunkedStateLog,1))
        orbitNumToPlot = size(chunkedStateLog,1);
        set(dAxes,'UserData',orbitNumToPlot);
    end
    subStateLogs = chunkedStateLog(orbitNumToPlot,:);
    eventsList = [];
    otherSC = maData.spacecraft.otherSC;
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
            [childrenHGs] = plotSubStateLog(subStateLogs{i}, prevSubStateLog, showSoI, showChildBodies, showChildMarker, showOtherSC, otherSC, lvdData, celBodyData, dAxes);
        end
    end
    
    bodyID = subStateLogs{1}(1,8);
    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
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
        setappdata(handles.ma_LvdMainGUI,'dispOrbitXLim',xlim(dAxes));
        setappdata(handles.ma_LvdMainGUI,'dispOrbitYLim',ylim(dAxes));
        setappdata(handles.ma_LvdMainGUI,'dispOrbitZLim',zlim(dAxes));
        applyZoomLevel(handles.ma_LvdMainGUI, handles, celBodyData);
    end
end

function [childrenHGs] = plotSubStateLog(subStateLog, prevSubStateLog, showSoI, showChildBodies, showChildMarker, showOtherSC, otherSCs, lvdData, celBodyData, dAxes)    
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

    hold(dAxes,'on');
	plot3(dAxes, [prevSubStateLog(end,2);subStateLog(1:end,2)], [prevSubStateLog(end,3);subStateLog(1:end,3)], [prevSubStateLog(end,4);subStateLog(1:end,4)], 'Color', plotLineColor, 'LineStyle', plotLineStyle, 'LineWidth',1.5);    %  plotColors(subStateLog(1,13))
   
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
            childrenHGs(end+1,:) = {child, hBody1, hBody2, hOrbit}; %#ok<AGROW>
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