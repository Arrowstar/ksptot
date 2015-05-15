function eventLogCoast = ma_executeCoast_goto_soi_trans(coastINIState, eventNum, maxSearchUT, soiSkipIds, celBodyData, varargin)
%ma_executeCoast_goto_soi_trans Summary of this function goes here
%   Detailed explanation goes here
    bodyID = coastINIState(8);

    if(~isempty(varargin))
        soITrans = varargin{1};
    else
        soITrans = findSoITransitions(coastINIState, maxSearchUT, soiSkipIds, celBodyData);
    end
    
    if(isempty(soITrans))
        warnStr = 'Cannot coast to SoI transition: no SoI transitions found.  Skipping.';
        addToExecutionWarnings(warnStr, eventNum, bodyID, celBodyData);
        eventLogCoast = coastINIState;
        eventLogCoast(:,13) = eventNum;
        return;
    else
        firstSoITrans = soITrans(soITrans(:,2) == min(soITrans(:,2)), :);
        if(size(firstSoITrans,1)>1)
            firstSoITrans = firstSoITrans(1,:);
        end
        eventLogCoast = ma_executeCoast_goto_ut(firstSoITrans(2), coastINIState, eventNum, false, soiSkipIds, celBodyData);
        
        eventLogCoast(end+1,:) = [firstSoITrans(2), ...
                                  firstSoITrans(11:13), ...
                                  firstSoITrans(14:16), ...
                                  firstSoITrans(4), ...
                                  coastINIState(9:12), ...
                                  eventNum];
    end
end

