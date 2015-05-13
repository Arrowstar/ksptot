function rts_propUpdateFunc(~, ~, hFig, tcpipClientRes, tcpipClientMainEng, tcpipClientRcsEng, hResUITable1, hResSumProgBar1, hResUITable2, hResSumProgBar2, hResourceCombo1, hResourceCombo2, hMainEngineUITable, hRcsEngineUITable)
%rts_propUpdateFunc Summary of this function goes here
%   Detailed explanation goes here
   
    try
        data = get(tcpipClientRes,'UserData');
        resources = getResourcesStruct(data{1}, 3);

        if(~isempty(resources))
            %UPDATE RESOURSE COMBOBOX 1
            if(~isempty(hResourceCombo1))
                updateResComboKeepSelection(hResourceCombo1, resources);
            end
            
            %UPDATE RESOURSE COMBOBOX 2
            if(~isempty(hResourceCombo2))
                updateResComboKeepSelection(hResourceCombo2, resources);
            end
            
            %UPDATE RESOURCE TABLE 1
            resource = getResourceNameFromCombo(hResourceCombo1);
            if(~isempty(hResUITable1) && ~isempty(hResSumProgBar1) && isfield(resources, resource))
                generateResourceStorageTable(hResUITable1, resources.(resource));
                [progBar1Str,percent] = generateResourceSummaryStr(resources, resource);
                hResSumProgBar1.setValue(percent);
                hResSumProgBar1.setString(progBar1Str);
                hResSumProgBar1.setStringPainted(true);
            end 
            
            %UPDATE RESOURCE TABLE 2
            resource = getResourceNameFromCombo(hResourceCombo2);
            if(~isempty(hResUITable2) && ~isempty(hResSumProgBar2) && isfield(resources, resource))
                generateResourceStorageTable(hResUITable2, resources.(resource));
                [progBar2Str,percent] = generateResourceSummaryStr(resources, resource);
                hResSumProgBar2.setValue(percent);
                hResSumProgBar2.setString(progBar2Str);
                hResSumProgBar2.setStringPainted(true);
            end 
        end
        
        %UPDATE MAIN ENGINE TABLE
        data = get(tcpipClientMainEng,'UserData');
        r = readPartStrAndDblsFromDblArr(data{1}, 6);
        if(~isempty(r))
            if(~isempty(hMainEngineUITable))
                generateMainEngineStatusTable(hMainEngineUITable, r);
            end
        end
        
        %UPDATE RCS ENGINE TABLE
        data = get(tcpipClientRcsEng,'UserData');
        r = readPartStrAndDblsFromDblArr(data{1}, 3);
        if(~isempty(r))
            if(~isempty(hRcsEngineUITable))
                generateRCSEngineStatusTable(hRcsEngineUITable, r);
            end
        end
        
    catch ME
%         disp('----');
%         disp(ME.message);
%         disp(ME.stack(1));
%         disp(ME.stack(2));
%         disp('----');
    end        

end

function generateRCSEngineStatusTable(hRcsEngineUITable, tData)
    tableData = {};
    for(i=1:size(tData,1))
        row = tData(i,:);
        split = strsplit(row{1}, '/_/_/');
        
        tableData{i,1} = split{1};
        tableData{i,2} = row{2};
        tableData{i,3} = row{3};
        tableData{i,4} = row{4};
    end
    
    setTableData(hRcsEngineUITable, tableData);
end

function generateMainEngineStatusTable(hMainEngineUITable, tData)
    tableData = {};
    for(i=1:size(tData,1))
        row = tData(i,:);
        split = strsplit(row{1}, '/_/_/');
        
        tableData{i,1} = split{1};
        tableData{i,2} = row{2}*100;
        tableData{i,3} = row{3};
        tableData{i,4} = row{4};
        tableData{i,5} = row{5};
    end
    
    setTableData(hMainEngineUITable, tableData);
end

function str = getResourceNameFromCombo(hResourceCombo)
    contents = cellstr(get(hResourceCombo,'String'));
    str = contents{get(hResourceCombo,'Value')};
end

function updateResComboKeepSelection(hResourceCombo, resources)
    contents = cellstr(get(hResourceCombo,'String'));
    if(get(hResourceCombo,'Value') <= length(contents))
        sel = contents{get(hResourceCombo,'Value')};
    else
        sel = '';
    end
    
    res = sort(fieldnames(resources));
    if(~isempty(res))
        set(hResourceCombo,'String', res);
        ind=find(ismember(res,sel));
    else
        return;
    end
    
    if(isempty(ind) || ind<=0)
        value = 1;
    else
        value = ind;
    end
    
    set(hResourceCombo,'Value', value);
end

function [str,percent] = generateResourceSummaryStr(resources, resource)
    [current, max] = getCurrentMaxResource(resources, resource);
    
    percent = uint32(round(100*(current/max)));
    resStr = cap1stLetter(resource);
    
    strT = ['Total ', resStr ,' = ',num2str(current),' / ',num2str(max)];
    str = java.lang.String(strT);
end

function generateResourceStorageTable(hResUITable, resArr) 
    tableData = {};
    for(i=1:size(resArr,1))
        if(resArr{i,6} == 1)
            connected = 'True'; 
        else
            connected = 'False';
        end
        
        tableData{i,1} = resArr{i,2};
        tableData{i,2} = connected;
        tableData{i,3} = resArr{i,4};
        tableData{i,4} = resArr{i,5};
    end
    
    setTableData(hResUITable, tableData);
end
