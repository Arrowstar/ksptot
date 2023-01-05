function updateAppOptions(hMainUI, header, key, value)
%updateAppOptions Summary of this function goes here
%   Detailed explanation goes here
    key = lower(key);

    appOptions = getappdata(hMainUI,'appOptions');
    appOptions.(header).(key) = value;
    setappdata(hMainUI,'appOptions',appOptions);
    
    appOptionsFromINI = getIniCellsFromStruct(appOptions);
    inifile('appOptions.ini','write',appOptionsFromINI);
end

function iniStruct = getIniCellsFromStruct(optStruct)
    headers = fieldnames(optStruct);
    iniStruct = cell(length(fields(optStruct.(headers{1}))),4);
    for(i=1:numel(iniStruct))
        iniStruct{i} = '';
    end
    
    for(i=1:length(headers)) %#ok<*NO4LP>
        header = headers{i};
        
        subOptions = fieldnames(optStruct.(header));
        for(j=1:length(subOptions))
            iniStruct(j,:) = {header, '', subOptions{j}, optStruct.(header).(subOptions{j})};
        end
    end
end
