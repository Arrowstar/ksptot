function lvd_updateDispAxis(handles, maStateLog, orbitNumToPlot, lvdData)
%lvd_updateDispAxis Summary of this function goes here
%   Detailed explanation goes here    
    hDispAxes = handles.dispAxes;
%     hShowSoICheckBox = handles.showSoICheckBox;
%     hShowChildrenCheckBox = handles.showChildrenCheckBox;
    hDispAxisTitleLabel = handles.dispAxisTitleLabel;
%     hShowOtherSpacecraftCheckBox = handles.showOtherSpacecraftCheckBox;
%     hShowChildBodyMarker = handles.showChildBodyMarker;
    
    if(isempty(orbitNumToPlot))
        orbitNumToPlot = 1;
        set(hDispAxes,'UserData',orbitNumToPlot);
    end

%     showSoICheckBoxINT = get(hShowSoICheckBox,'value');
%     if(showSoICheckBoxINT == 1)
%         showSoI = true;
%     else
        showSoI = false;
%     end
    
%     hShowChildrenCheckBoxINT = get(hShowChildrenCheckBox,'value');
%     if(hShowChildrenCheckBoxINT == 1)
%         showChildBodies = true;
%     else
        showChildBodies = false;
%     end
    
%     hShowOtherSpacecraftCheckBoxINT = get(hShowOtherSpacecraftCheckBox,'value');
%     if(hShowOtherSpacecraftCheckBoxINT == 1)
%         showOtherSC = true;
%     else
        showOtherSC = false;
%     end
    
%     showChildBodyMarkerINT = get(hShowChildBodyMarker,'value');
%     if(showChildBodyMarkerINT == 1)
%         showChildMarker = true;
%     else
        showChildMarker = false;
%     end
    
    axes(hDispAxes);
    cla(gca);
    maData = getappdata(handles.ma_LvdMainGUI,'maData');
    celBodyData = getappdata(handles.ma_LvdMainGUI,'celBodyData');
    lvd_plotStateLog(maStateLog, [], showSoI, showChildBodies, showChildMarker, showOtherSC, orbitNumToPlot, hDispAxisTitleLabel, maData, lvdData, celBodyData);
end