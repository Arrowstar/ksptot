function [celBodyData] = processINIBodyInfo(celBodyDataFromINI)
%processINIBodyInfo Summary of this function goes here
%   Detailed explanation goes here

    celBodyData = struct();
    for(i=1:size(celBodyDataFromINI,1))
        row = celBodyDataFromINI(i,:);
        
        if(isempty(find(isstrprop(row{4},'digit'), 1)))
            entry = row{4};
        else
            entry = str2double(row{4});
        end
        
        if(isfield(celBodyData,row{1}))
            celBodyData.(row{1}).(row{3}) = entry;
        else 
            celBodyData.(row{1}) = struct();
            celBodyData.(row{1}).(row{3}) = entry;
        end
        
%         disp('###############');
%         disp(['Processing CelBodyData: ', row{1}, ' - ', row{3}, ' - ', num2str(entry)]);
    end
    
    return;
end

