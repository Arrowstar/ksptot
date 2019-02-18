function optVar = ma_createOptimizationVariable(eventNum, numVars, x0, lb, ub, varStr)
%ma_createOptimizationVariable Summary of this function goes here
%   Detailed explanation goes here

    optVar = struct();
    optVar.eventNum = eventNum;
    optVar.numVars  = numVars;
    optVar.x0       = x0;
    optVar.lb       = lb;
    optVar.ub       = ub;
    optVar.varStr   = varStr;
end

