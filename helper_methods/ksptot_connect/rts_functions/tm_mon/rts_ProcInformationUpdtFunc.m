function rts_ProcInformationUpdtFunc(~,~, hRtsMainGUI, hTable)
%rts_ProcInformationUpdtFunc Summary of this function goes here
%   Detailed explanation goes here
    timers = getappdata(hRtsMainGUI,'timers');

	tableData = {};
    try
        validtimers = timer.empty(1,0);
        for(i=1:length(timers))
            if(isvalid(timers(i)))
                validtimers(end+1) = timers(i);
            else
                delete(timers(i));
            end
        end

        for(i=1:length(validtimers))
            task = validtimers(i);
            
            if(isvalid(task))
                tableData{i,1} = get(task,'Name');
                tableData{i,2} = cap1stLetter(get(task,'Running'));
                tableData{i,3} = cap1stLetter(get(task,'ExecutionMode'));
                tableData{i,4} = num2str(get(task,'Period'));
            else
                delete(task);
            end
        end     
        
        setTableData(hTable, tableData)
    catch ME

    end 
end

