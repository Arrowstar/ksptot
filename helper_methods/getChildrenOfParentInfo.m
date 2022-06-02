function [children, childrenNames] = getChildrenOfParentInfo(celBodyData, cbName)
%getChildrenOfParentInfo Summary of this function goes here
%   Detailed explanation goes here

    children = {};
    childrenNames = {};
    fields = fieldnames(celBodyData);
    for(i=1:numel(fields)) %#ok<*NO4LP>
        body = celBodyData.(fields{i});
        if(strcmpi(body.parent,cbName))
            children{end+1} = body;
            childrenNames{end+1} = body.name;
        end
    end
end

