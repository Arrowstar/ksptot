function [cbBodyNames, arriveDepartNames, allNames] = genCBArriveDepartComboBoxStrs(mainGUIHandle)
%genCBArriveDepartComboBoxStrs Summary of this function goes here
%   Detailed explanation goes here
    userData = get(mainGUIHandle,'UserData');
    celBodyData = userData{1,1};
    
    hCentralBodyCombo = findobj(mainGUIHandle,'Tag','centralBodyCombo');
    contents = cellstr(get(hCentralBodyCombo,'String'));
    curSelCB = lower(contents{get(hCentralBodyCombo,'Value')});
    
    if(strcmp(curSelCB,'pop-up menu'))
        curSelCB='Sun';
    end
    
    cbBodyNames = {};
    arriveDepartNames = {};
    allNames = {};
    bodyNames = fieldnames(celBodyData);
    
    for(i=1:length(bodyNames))  %#ok<*NO4LP>
        if(celBodyData.(bodyNames{i}).canbecentral == 1)
            cbBodyNames{end+1} = bodyNames{i}; %#ok<AGROW>
        end
        
        if(celBodyData.(bodyNames{i}).canbearrivedepart == 1 && strcmpi(celBodyData.(bodyNames{i}).parent,curSelCB))
            arriveDepartNames{end+1} = bodyNames{i}; %#ok<AGROW>
        end
        allNames{end+1} = bodyNames{i}; %#ok<AGROW>
    end
    
    return;
end

