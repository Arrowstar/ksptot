function populateStationsCombo(handles, hRefStationsCombo)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    
    if(isfield(maData.spacecraft,'stations'))
        stations = maData.spacecraft.stations;
        if(isempty(stations))
            set(hRefStationsCombo, 'Enable','off');
            set(hRefStationsCombo,'String', 'None Available');
        else
            set(hRefStationsCombo, 'Enable','on');

            stnStr = cell(0,1);
            for(i=1:length(stations)) %#ok<*NO4LP>
                stnStr{end+1} = stations{i}.name; %#ok<AGROW>
            end
            set(hRefStationsCombo,'String',stnStr);
        end
    else
        set(hRefStationsCombo, 'Enable','off');
        set(hRefStationsCombo,'String', 'None Available');
    end
end