function [actConsts] = ma_getConstCellArr(actConsts, constStr, constFunc, type, unit, lbLim, ubLim, lbVal, ubVal, body, eventNum, eventID, othersc, lbActive, ubActive)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

    actConsts{end+1,1} = constStr;
    actConsts{end,2} = constFunc;
    actConsts{end,3} = type;
    actConsts{end,4} = unit;
    actConsts{end,5} = [lbLim, ubLim, lbVal, ubVal, body, eventNum, eventID, othersc, lbActive, ubActive];
end

