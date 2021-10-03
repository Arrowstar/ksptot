function [stop, options] = msOutFcn(optimValues, ~, totIterExpect, hWaitBar, iniMessage, ticID)
    elapsedTime = toc(ticID);
    avgTimePerRun = elapsedTime/optimValues.localrunindex;
    runsRemaining = totIterExpect - optimValues.localrunindex;
    estTimeRemaining = runsRemaining*avgTimePerRun;
    
    [timeRemainingStr] = getDurationStr(estTimeRemaining);
%     timeRemainingStr =  num2str(estTimeRemaining, '%8.3f');
%     timeRemainingStr = paddStr(timeRemainingStr, 7);
    
    if(isnan(estTimeRemaining) || ~isempty(strfind(timeRemainingStr,'NaN')))
        estTimeStr = '';
    else
        estTimeStr = ['Est. Time Left: ', timeRemainingStr];
    end

    msgStr = {[iniMessage, ' [',num2str(optimValues.localrunindex),'/',num2str(totIterExpect),']'],...
              estTimeStr};
    
    if(isa(hWaitBar, 'matlab.ui.dialog.ProgressDialog'))
        hWaitBar.Message = msgStr;
        hWaitBar.Value = optimValues.localrunindex/totIterExpect;
    else
        waitbar(optimValues.localrunindex/totIterExpect, hWaitBar, msgStr);
    end
    
    stop = false;
    if(nargout == 2)
        options=[];
    end    
end