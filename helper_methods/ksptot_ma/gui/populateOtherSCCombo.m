function populateOtherSCCombo(handles, hRefSpacecraftCombo)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    
    if(isfield(maData.spacecraft,'otherSC'))
        otherSC = maData.spacecraft.otherSC;
        if(isempty(otherSC))
            set(hRefSpacecraftCombo, 'Enable','off');
            set(hRefSpacecraftCombo,'String', 'None Available');
        else
            set(hRefSpacecraftCombo, 'Enable','on');

            oSCStr = cell(0,1);
            for(i=1:length(otherSC))
                oSCStr{end+1} = otherSC{i}.name;
            end
            set(hRefSpacecraftCombo,'String',oSCStr);
        end
    else
        set(hRefSpacecraftCombo, 'Enable','off');
        set(hRefSpacecraftCombo,'String', 'None Available');
    end
end