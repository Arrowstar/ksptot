function [sortedBodyNames, sortedBodyInfo] = ma_getSortedBodyNames(celBodyData, varargin)
%ma_getSortedBodyNames Summary of this function goes here
%   Detailed explanation goes here

    if(isempty(varargin))
        curLevel = 1;
        maxLevel = Inf;
    elseif(length(varargin)==1)
        curLevel = 1;
        maxLevel = varargin{1};
    else
        curLevel = varargin{2};
        maxLevel = varargin{1};
    end
    
    if(curLevel == 1)
        topLevelBodyInfo = getTopLevelCentralBody(celBodyData);
        curParent = topLevelBodyInfo;
        sortedBodyNames = {curParent.name};
    else
        curParent = varargin{3};
        sortedBodyNames = {};
    end
    
    if(curLevel < maxLevel)
        numIndents = curLevel;
        childBodies = getChildrenOfParentInfo(celBodyData, curParent.name);
        childBodies = sortChildrenBySma(childBodies);
        for(i=1:length(childBodies)) %#ok<*NO4LP>
            childBody = childBodies{i};
            sortedBodyNames{end+1} = paddStrLeft(childBody.name, length(childBody.name)+numIndents); %#ok<AGROW>


            sortedChildBodyNames = ma_getSortedBodyNames(celBodyData, maxLevel, curLevel+1, childBody);
            for(j=1:length(sortedChildBodyNames))
                sortedBodyNames{end+1} = sortedChildBodyNames{j}; %#ok<AGROW>
            end        
        end
    end
    
    sortedBodyNames = sortedBodyNames';
    sortedBodyInfo = cell(size(sortedBodyNames));
    for(i=1:length(sortedBodyNames))
        sortedBodyInfo{i} = celBodyData.(strtrim(lower(sortedBodyNames{i})));
    end
end

function smaSortedChildren = sortChildrenBySma(childBodies)
    [~,I] = sort(cellfun(@sortSmaCellFun, childBodies));
    smaSortedChildren = childBodies(I);
end

function sma = sortSmaCellFun(bodyInfo)
    sma = bodyInfo.sma;
end