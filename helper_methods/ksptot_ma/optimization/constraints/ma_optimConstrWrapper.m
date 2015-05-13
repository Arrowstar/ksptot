function [c, ceq] = ma_optimConstrWrapper(x, script,variables,constFuncts, celBodyData)
%ma_optimConstrWrapper Summary of this function goes here
%   Detailed explanation goes here

    script = ma_updateOptimScript(x, script, variables);
    stateLog = ma_produceStateLogFromScript(script, celBodyData);

    c = [];
    ceq = [];
    for(cFunArr = constFuncts) %#ok<*NO4LP>
        cFun = cFunArr{1};
        [c1, ceq1] = cFun(stateLog);
        c   = [c,c1]; %#ok<AGROW>
        ceq = [ceq, ceq1]; %#ok<AGROW>
    end
end

