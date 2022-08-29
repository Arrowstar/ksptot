function numOsc = populateOtherSCCombo(handles, hRefSpacecraftCombo)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    
    oSCStr = cell(0,1);
    if(isfield(maData.spacecraft,'otherSC'))
        otherSC = maData.spacecraft.otherSC;
        if(isempty(otherSC))
            set(hRefSpacecraftCombo, 'Enable','off');
            set(hRefSpacecraftCombo,'String', 'None Available');
        else
            set(hRefSpacecraftCombo, 'Enable','on');
            
            for(i=1:length(otherSC)) %#ok<*NO4LP>
                oSCStr{end+1} = otherSC{i}.name; %#ok<AGROW>
            end
            set(hRefSpacecraftCombo,'String',oSCStr);
        end
    else
        set(hRefSpacecraftCombo, 'Enable','off');
        set(hRefSpacecraftCombo,'String', 'None Available');
    end
    
    numOsc = length(oSCStr);
end