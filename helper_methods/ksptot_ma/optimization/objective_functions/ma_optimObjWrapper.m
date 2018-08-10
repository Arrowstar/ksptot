function [f, stateLog] = ma_optimObjWrapper(x, script,variables,objFunc,maData,celBodyData, partialExec)
%ma_optimObjWrapper Summary of this function goes here
%   Detailed explanation goes here
    script = ma_updateOptimScript(x, script, variables);
    [stateLog] = ma_produceStateLogFromScript(script,maData,celBodyData, partialExec);
    
    f = objFunc(stateLog);
    if(length(f) > 1)
        f = f(1);
    end
end