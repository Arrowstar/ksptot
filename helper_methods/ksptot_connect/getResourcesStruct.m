function [resources] = getResourcesStruct(resDblArr, numDbl)
%getResourcesStruct Summary of this function goes here
%   Detailed explanation goes here

    r = readPartStrAndDblsFromDblArr(resDblArr, numDbl);

    resources = struct();
    for(i=1:size(r,1))
        resourcePart = r{i,1};
        split = strsplit(resourcePart, '/_/_/');
        resName = lower(split{1});

        if(~isfield(resources,resName))
            resources.(resName) = cell(0);
        end

        rArrOrig = resources.(resName);
        rArr = [split, r{i,2:end}];
        rArrOrig(end+1,:) = rArr;

        resources.(resName) = rArrOrig;
    end
end

