function [goodTF, msg] = verifyCelBodyData(celBodyData)
    %verifyCelBodyData Summary of this function goes here
    %   Detailed explanation goes here
    goodTF = true;
    msg = {};
    
    numTopLvlBodies = 0;
    topLevelBodies = KSPTOT_BodyInfo.empty(1,0);
    bodyIds = [];
    bodyNames = {};
    topLevelBodyIdStrs = {};
    celBodyFields = fields(celBodyData);
    for(i=1:length(celBodyFields)) %#ok<*NO4LP> 
        bInfo = celBodyData.(celBodyFields{i});
        bodyIds(end+1) = bInfo.id; %#ok<AGROW>
        bodyNames{end+1} = bInfo.name; %#ok<AGROW>
        
        if(isempty(bInfo.parentBodyInfo))
            numTopLvlBodies = numTopLvlBodies + 1;
            topLevelBodies(end+1) = bInfo; %#ok<AGROW>
            topLevelBodyIdStrs{end+1} = fullAccNum2Str(bInfo.id); %#ok<AGROW>
        end

        bInfo.getHeightMap(); %verify that if height maps are requested that they actually do load.
    end
    
    if(numTopLvlBodies ~= 1)
        goodTF = false;
        
        idStr = strjoin(topLevelBodyIdStrs,', ');
        msg{end+1} = sprintf('Multiple bodies have been detected without parents.  Only one body should be the "top-level" body without a parent body.  Detected body IDs: %s', idStr);
    end    
    
    if(numel(bodyIds) ~= numel(unique(bodyIds)))
        goodTF = false;
        
        msg{end+1} = 'Duplicate body IDs were found.  Check to ensure that all bodies have unique integer ID numbers.';
    end
    
    if(numel(bodyNames) ~= numel(unique(bodyNames)))
        goodTF = false;
        
        msg{end+1} = 'Duplicate body names were found.  Check to ensure that all bodies have unique name.';
    end
end