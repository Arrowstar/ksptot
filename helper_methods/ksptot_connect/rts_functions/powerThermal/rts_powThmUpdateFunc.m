function rts_powThmUpdateFunc(~, ~, hFig, tcpipClientRes, tcpipClientSP, tcpipClientTemps, hElecChargeUITable, hElecChargeSumLabel, hSolarPanelUITable, hTotECGenRateLabel, hPartTempUITable, hElecChargeSumProgBar1)
%rts_resourcesUpdateFunc Summary of this function goes here
%   Detailed explanation goes here
    try
        data = get(tcpipClientRes,'UserData');
        resources = getResourcesStruct(data{1}, 3);
        if(~isempty(resources))
            %UPDATE ELECTRIC CHARGE TABLE
            if(~isempty(hElecChargeUITable) && ~isempty(hElecChargeSumLabel) && isfield(resources, 'electriccharge'))
                generateElecChargeStorageTable(hElecChargeUITable, resources.electriccharge);
                [progBar1Str, percent] = generateElecChargeSummaryStr(resources);
                hElecChargeSumProgBar1.setValue(percent);
                hElecChargeSumProgBar1.setString(progBar1Str);
                hElecChargeSumProgBar1.setStringPainted(true);
            end 
        end
        
        data = get(tcpipClientSP,'UserData');
        r = readPartStrAndDblsFromDblArr(data{1}, 5);
        if(~isempty(r))
            if(~isempty(hSolarPanelUITable) && ~isempty(hTotECGenRateLabel))
                generateSolarPanelStatusTable(hSolarPanelUITable, r);
                set(hTotECGenRateLabel,'String',generateSPGenerationSummaryStr(r));
            end
        end
        
        data = get(tcpipClientTemps, 'UserData');
        r = readPartStrAndDblsFromDblArr(data{1}, 2);
        if(~isempty(r))
            if(~isempty(hPartTempUITable))
                generateTempsStatusTable(hPartTempUITable, r);
            end
        end
        
    catch ME
        disp('----');
        disp(ME.message);
        disp(ME.stack(1));
        disp(ME.stack(2));
        disp('----');
    end
end

function generateTempsStatusTable(hPartTempUITable, tData)
    tableData = {};
    for(i=1:size(tData,1))
        row = tData(i,:);
        split = strsplit(row{1}, '/_/_/');
        
        tableData{i,1} = split{1};
        tableData{i,2} = row{2};
        tableData{i,3} = row{3};
    end
    
%     temps = cell2mat(tableData(:,2));
    [~,IX] = sort(cell2mat(tableData(:,2)),'descend');
    
    tableData = tableData(IX,:);
    setTableData(hPartTempUITable, tableData);
end

function str = generateSPGenerationSummaryStr(spData)
    totGenRate = 0;
    for(i=1:size(spData,1))
        totGenRate = totGenRate + spData{i,2};
    end
    
    str = ['Total Generation Rate = ', num2str(totGenRate), ' units/s'];
end

function generateSolarPanelStatusTable(hSolarPanelUITable, spData)
    tableData = {};
    for(i=1:size(spData,1))
        row = spData(i,:);
        split = strsplit(row{1}, '/_/_/');
        
        switch(row{5})
            case 0
                status = 'Retracted';
            case 1
                status = 'Extended';
            case 2
                status = 'Retracting';
            case 3
                status = 'Extending';
            case 4
                status = 'Broken/Failed';
            otherwise
                status = 'Unknown';
        end
        
        if(row{6} == 1)
            suntrack = 'True';
        else
            suntrack = 'False';
        end
        
        tableData{i,1} = split{1};
        tableData{i,2} = status;
        tableData{i,3} = row{2};
        tableData{i,4} = row{4};
        tableData{i,5} = suntrack;
    end
    
    setTableData(hSolarPanelUITable, tableData);
end

function [str, percent] = generateElecChargeSummaryStr(resources)
    resource = 'electriccharge';
    [current, max] = getCurrentMaxResource(resources, resource);
    
    percent = uint32(round(100*(current/max)));
    strT = ['Total Electric Charge = ',num2str(current),' / ',num2str(max)];
    str = java.lang.String(strT);
end

function generateElecChargeStorageTable(hElecChargeUITable, ecArr) 
    tableData = {};
    for(i=1:size(ecArr,1))
        if(ecArr{i,6} == 1)
            connected = 'True'; 
        else
            connected = 'False';
        end
        
        tableData{i,1} = ecArr{i,2};
        tableData{i,2} = connected;
        tableData{i,3} = ecArr{i,4};
        tableData{i,4} = ecArr{i,5};
    end
    
    setTableData(hElecChargeUITable, tableData);
end
