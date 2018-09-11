function [c, ceq, value, lb, ub, type, eventNum] = ma_optimConstrWrapper(x, script,variables,constFuncts,maData,celBodyData, partialExec)
%ma_optimConstrWrapper Summary of this function goes here
%   Detailed explanation goes here

    script = ma_updateOptimScript(x, script, variables);
    stateLog = ma_produceStateLogFromScript(script, maData, celBodyData, partialExec);

    c = [];
    ceq = [];
    value = [];
    lb = [];
    ub = [];
    type = {};
    eventNum = [];
    for(cFunArr = constFuncts) %#ok<*NO4LP>
        cFun = cFunArr{1};
        [c1, ceq1, value1, lb1, ub1, type1, eventNum1] = cFun(stateLog);
        c   = [c,c1]; %#ok<AGROW>
        ceq = [ceq, ceq1]; %#ok<AGROW>
        value = [value, value1]; %#ok<AGROW>
        lb = [lb, lb1]; %#ok<AGROW>
        ub = [ub, ub1]; %#ok<AGROW>
        type = horzcat(type, type1); %#ok<AGROW>
        eventNum = [eventNum, eventNum1]; %#ok<AGROW>
    end
end

